local network = require "pokedex.network"
local notify = require "utils.notify"

local KEY = "INITIAL_CONNECTION"

local function on_client_connected(client)
	local initial_packet = {
		version = version,
	}
	M.server_send_data(INITIAL_PACKET_KEY, initial_packet, client)
end

local function on_client_initial_packet(packet)
	local server_version = "Unknown"
	local client_version = network.get_version()
	
	if packet and packet.version then
		server_version = packet.version
	end

	if server_version ~= client_version then
		notify.notify("Disconnected from server due to mismatched versions (was " .. tostring(server_version) .. ", ours is " .. tostring(client_version) .. ')')
		network.stop_client()
	else
		-- TODO could have other systems register for initial connection stuff
	end	
end

local M = {}

function M.init()
	network.register_client_connected_callback(on_client_connected)
	network.register_client_callback(KEY, on_client_initial_packet)
end

return M