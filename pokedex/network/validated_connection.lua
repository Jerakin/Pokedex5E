local netcore = require "pokedex.network.netcore"
local notify = require "utils.notify"

local KEY = "VALIDATED_CONNECTION"
local on_connected_callbacks = {}
local is_connected = false

-- TODO: these functions are pretty confusingly named

local function on_server_active_callback(active)
	if active ~= is_connected then
		is_connected = active
		for i=1,#on_connected_callbacks do
			on_connected_callbacks[i](active)
		end	
	end
end

local function on_client_connected(client)
	local initial_packet = {
		version = netcore.get_version(),
	}
	netcore.send_to_client(KEY, initial_packet, client)
end

local function on_client_disconnect()
	if is_connected then
		is_connected = false

		for i=1,#on_connected_callbacks do
			on_connected_callbacks[i](false)
		end
	end
end

local function on_client_initial_packet(packet)
	if not is_connected then
		local server_version = "Unknown"
		local client_version = netcore.get_version()
		
		if packet and packet.version then
			server_version = packet.version
		end

		if server_version ~= client_version then
			notify.notify("Could not connect! Version mismatch:\n\"" .. tostring(server_version) .. "\" vs. \"" .. tostring(client_version) .. "\"")
			netcore.stop_client()
		else
			-- TODO could have other systems register for initial connection stuff
			is_connected = true

			for i=1,#on_connected_callbacks do
				on_connected_callbacks[i](true)
			end
		end	
	end
end

local M = {}

function M.init()
	netcore.register_client_connected_callback(on_client_connected)
	netcore.register_client_callback(KEY, on_client_initial_packet)
	netcore.register_server_active_callback(on_server_active_callback)
	netcore.register_client_disconnect(on_client_disconnect)
end

function M.register_connection_change(cb)
	table.insert(on_connected_callbacks, cb)
end

function M.is_connected()
	return is_connected
end

return M