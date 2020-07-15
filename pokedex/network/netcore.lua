local p2p_discovery = require "defnet.p2p_discovery"
local tcp_server = require "defnet.tcp_server"
local tcp_client = require "defnet.tcp_client"
local ljson = require "defsave.json"
local notify = require "utils.notify"

local p2p
local server
local version

local BROADCAST_PORT = 50000

local is_verified_client_connected = false
local client_connect_initial_data = {}

local client_data_cbs = {}
local server_data_cbs = {}
local connection_changed_cbs = {}

local INITIAL_PACKET_KEY = "INITIAL_PACKET"
local FAKE_SERVER_CLIENT = {}

local M = {}

local function get_broadcast_name()
	return "Pokedex5E-" .. version
end

local function server_on_data(data, ip, port, client)
	local response = nil
	local success = false
	if pcall(function() json_data = json.decode(data) end) then
		if type(json_data) == "table" and json_data.key and type(json_data.key) == "string" and json_data.payload then
			local cb = server_data_cbs[json_data.key]
			if cb then
				response = cb(client, json_data.payload)
				success = true
			end
		end
	end

	if not success then
		print("Server received unknown data: " .. tostring(data) .. " from client: " .. ip)
	end

	-- NOTE: Could send response as return value here, not sure how to do that best
end

local function client_process_initial_packet(packet)
	local server_version = "Unknown"
	local client_version = version

	if packet and packet.version then
		server_version = packet.version
	end

	if server_version ~= client_version then
		notify.notify("Could not connect! Version mismatch:\n\"" .. tostring(server_version) .. "\" vs. \"" .. tostring(client_version) .. "\"")
		M.stop_client()
	else
		-- TODO could have other systems register for initial connection stuff?
		is_verified_client_connected = true

		for i=1,#connection_changed_cbs do
			connection_changed_cbs[i](is_verified_client_connected)
		end
	end	
end

local function client_on_data(data)
	local success = false
	if pcall(function() json_data = json.decode(data) end) then
		if type(json_data) == "table" and json_data.key and type(json_data.key) == "string" and json_data.payload then

			-- Check for initial packet key
			if json_data.key == INITIAL_PACKET_KEY then
				client_process_initial_packet(json_data.payload)
				success = true
			else
				local cb = client_data_cbs[json_data.key]
				if cb then
					cb(json_data.payload)
					success = true
				end
			end
		end
	end

	if not success then
		print("Client received unknown data: " .. tostring(data))
	end
end

local function server_on_client_connected(ip, port, client)
	print("Client", ip, "connected")

	-- Send client a packet to indicate what version of the app we are - if they are using the wrong version, they are expected to disconnect.
	local initial_packet = {
		version = version,
	}

	-- TODO: Should there be other information in the initial packet? Perhaps a list of known members?
	
	M.send_to_client(INITIAL_PACKET_KEY, initial_packet, client)
end

local function server_on_client_disconnected(ip, port, client)
	print("Client", ip, "disconnected")
end

function M.init()
	local system = sys.get_sys_info().system_name
	if system == "Windows" then
		version = sys.get_config("gameanalytics.build_windows", nil)
	elseif system == "iPhone OS" then
		version = sys.get_config("gameanalytics.build_ios", nil)
	elseif system == "Android" then
		version = sys.get_config("gameanalytics.build_android", nil)
	elseif system == "HTML5" then
		version = sys.get_config("gameanalytics.build_html5", nil)
	end
end

function M.register_client_data_callback(key, fn)
	client_data_cbs[key] = fn
end

function M.register_server_data_callback(key, fn)
	server_data_cbs[key] = fn
end

function M.register_connection_change_cb(cb)
	table.insert(connection_changed_cbs, cb)
end

function M.update(dt)
	if p2p ~= nil then
		p2p.update()
	end
	if server ~= nil then
		server.update()
	end
	if client ~= nil then
		client.update()
	end
end

function M.final()
	p2p = nil
	M.stop_server()
	M.stop_client()
end

function M.find_broadcast(fn_found)
	M.stop_server()
	
	if version ~= nil and p2p == nil then
		p2p = p2p_discovery.create(BROADCAST_PORT)
	end
	p2p.listen(get_broadcast_name(), function(ip, port)
		fn_found(ip, port)
	end)
end

function M.start_server(port)
	p2p = nil
	M.stop_client()
	
	if server == nil then
		p2p = p2p_discovery.create(BROADCAST_PORT)
		p2p.broadcast(get_broadcast_name())
		
		server = tcp_server.create(port, server_on_data, server_on_client_connected, server_on_client_disconnected)
		server.start()

		for i=1,#connection_changed_cbs do
			connection_changed_cbs[i](true)
		end
		return true
	end
	return false
end

function M.stop_server()
	p2p = nil
	if server ~= nil then
		server.stop()
		server = nil

		for i=1,#connection_changed_cbs do
			connection_changed_cbs[i](false)
		end
	end
end

function M.start_client(server_ip, server_port)
	M.stop_server()
	
	if client == nil then
		client = tcp_client.create(server_ip, server_port, client_on_data, function()
			M.stop_client()
		end)
		return true
	end
	return false
end

function M.stop_client()
	if client ~= nil then
		local was_verified = is_verified_client_connected
		is_verified_client_connected = false
		client.destroy()
		client = nil

		if was_verified ~= is_verified_client_connected then
			for i=1,#connection_changed_cbs do
				connection_changed_cbs[i](is_verified_client_connected)
			end
		end
	end
end

function M.send_to_client(key, payload, client)
	if server ~= nil then
		if client ~= FAKE_SERVER_CLIENT then
			
			local data =
			{
				key=key,
				payload=payload,
			}
			local encoded = ljson.encode(data) .. "\n"
			server.send(encoded, client)
		else
			-- We are the client this is sending to, just call the client callback
			local cb = client_data_cbs[key]
			if cb then
				cb(payload)
			end
		end
	else
		print("TODO Error, tried to send to client when not the server - this is bad!")
	end
end

function M.send_to_server(key, payload)	
	if client ~= nil then		
		local data =
		{
			key=key,
			payload=payload,
		}
		local encoded = ljson.encode(data) .. "\n"
		client.send(encoded)		
	elseif server ~= nil then
		-- We ARE the server, just send straight to the callback
		local cb = server_data_cbs[key]
		if cb then
			cb(FAKE_SERVER_CLIENT, payload)
		end
	else
		print("TODO Error, not connected at all")
	end
end

function M.is_connected()
	return (server ~= nil) or (client ~= nil and is_verified_client_connected)
end

return M