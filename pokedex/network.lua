local p2p_discovery = require "defnet.p2p_discovery"
local tcp_server = require "defnet.tcp_server"
local tcp_client = require "defnet.tcp_client"

local p2p
local server
local version

local BROADCAST_PORT = 50000

local function get_broadcast_name()
	return "Pokedex5E-" .. version
end

local function on_server_data(data, ip, port, client)
	print("Server received", data, "from", ip)
	return "Some server response"
end

local function on_client_data(data)
	print("Client client received ", data)
end

local function on_client_connected(ip, port, client)
	print("Client", ip, "connected")
end

local function on_client_disconnected(ip, port, client)
	print("Client", ip, "disconnected")
end

local function broadcast()
	if version ~= nil and p2p == nil then
		p2p = p2p_discovery.create(BROADCAST_PORT)
		p2p.broadcast(get_broadcast_name())
	end
end

local M = {}

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
	if server ~= nil then
		server.stop()
		server = nil
	end
	if client ~= nil then
		client.destroy()
		client = nil
	end
end

function M.find_broadcast(fn_found)
	if version ~= nil and p2p == nil then
		p2p = p2p_discovery.create(BROADCAST_PORT)
		p2p.listen(get_broadcast_name(), function(ip, port)
			fn_found(ip, port)
		end)
	end
end

function M.start_server(port)
	if server == nil then
		broadcast()
		server = tcp_server.create(port, on_server_data, on_client_connected, on_client_disconnected)
		server.start()
	end
end

function M.server_send_message(message)
	if server ~= nil then
		server.broadcast(message)
	end
end

function M.start_client(server_ip, server_port)
	if client == nil then
		client = tcp_client.create(server_ip, server_port, on_client_data, function()
			client.destroy()
			client = nil
		end)
	end
end

function M.client_send_message(message)
	if client ~= nil then
		client.send(message)
	end
end

return M