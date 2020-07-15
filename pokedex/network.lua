local p2p_discovery = require "defnet.p2p_discovery"
local tcp_server = require "defnet.tcp_server"
local tcp_client = require "defnet.tcp_client"
local ljson = require "defsave.json"

local p2p
local server
local version

local BROADCAST_PORT = 50000

local client_callbacks = {}
local client_connected_callbacks = {}
local server_active_callbacks = {}
local server_callbacks = {}
local client_disconnect_callbacks = {}

local FAKE_SERVER_CLIENT = {}

local M = {}

local function get_broadcast_name()
	return "Pokedex5E-" .. version
end

local function on_server_data(data, ip, port, client)
	local success = false
	if pcall(function() json_data = json.decode(data) end) then
		if type(json_data) == "table" and json_data.key and type(json_data.key) == "string" and json_data.payload then
			local cb = server_callbacks[json_data.key]
			if cb then
				cb(client, json_data.payload)
				success = true
			end
		end
	end

	if not success then
		print("Server received unknown data: " .. tostring(data) .. " from client: " .. ip)
	end
end

local function on_client_data(data)
	local success = false
	if pcall(function() json_data = json.decode(data) end) then
		if type(json_data) == "table" and json_data.key and type(json_data.key) == "string" and json_data.payload then
			local cb = client_callbacks[json_data.key]
			if cb then
				cb(json_data.payload)
				success = true
			end
		end
	end

	if not success then
		print("Client received unknown data: " .. tostring(data))
	end
end

local function on_client_connected(ip, port, client)
	print("Client", ip, "connected")

	for i=1,#client_connected_callbacks do
		client_connected_callbacks[i](client)
	end
end

local function on_client_disconnected(ip, port, client)
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

-- TODO: these functions are pretty confusingly named

function M.register_client_callback(key, fn)
	client_callbacks[key] = fn
end

function M.register_server_callback(key, fn)
	server_callbacks[key] = fn
end

function M.register_client_connected_callback(cb)
	table.insert(client_connected_callbacks, cb)
end

function M.register_server_active_callback(cb)
	table.insert(server_active_callbacks, cb)
end

function M.register_client_disconnect(cb)
	table.insert(client_disconnect_callbacks, cb)
end

function M.get_version()
	return version
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
		
		server = tcp_server.create(port, on_server_data, on_client_connected, on_client_disconnected)
		server.start()

		for i=1,#server_active_callbacks do
			server_active_callbacks[i](true)
		end
	end
end

function M.stop_server()
	p2p = nil
	if server ~= nil then
		server.stop()
		server = nil

		for i=1,#server_active_callbacks do
			server_active_callbacks[i](false)
		end
	end
end

function M.start_client(server_ip, server_port)
	M.stop_server()
	
	if client == nil then
		client = tcp_client.create(server_ip, server_port, on_client_data, function()
			M.stop_client()
		end)
	end
end

function M.stop_client()
	if client ~= nil then
		client.destroy()
		client = nil

		for i=1,#client_disconnect_callbacks do
			client_disconnect_callbacks[i]()
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
			-- We are the client this is sending to, jsu call the client callback
			local cb = client_callbacks[key]
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
		local cb = server_callbacks[key]
		if cb then
			cb(FAKE_SERVER_CLIENT, payload)
		end
	else
		print("TODO Error, not connected at all")
	end
end

return M