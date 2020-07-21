local netcore = require "pokedex.network.netcore"
local broadcast = require "utils.broadcast"
local p2p_discovery = require "defnet.p2p_discovery"
local notify = require "utils.notify"

local p2p
local local_host_info = nil
local DEFAULT_HOST_PORT = 9120
local DISCOVERY_PORT = 50120

local TEMP_printed_update = false

local M = {}

M.MSG_LOCAL_HOST_FOUND = hash("net_connection_local_host_found")
M.MSG_STATE_CHANGED = hash("net_connection_state_changed")

M.STATE_FINAL = "final"
M.STATE_IDLE = "idle"
M.STATE_HOSTING = "hosting"
M.STATE_CONNECTING = "connecting"
M.STATE_CONNECTED = "connected"

local current_state = M.STATE_IDLE

local function get_broadcast_name()
	return "Pokedex5E-" .. netcore.get_version()
end

local function change_state_to(new_state)
	if new_state ~= current_state and current_state ~= M.STATE_FINAL then
		if new_state == M.STATE_HOSTING then
			if current_state == M.STATE_CONNECTING or current_state == M.STATE_CONNECTED then
				netcore.stop_client()
			end
		elseif new_state == M.STATE_CONNECTING then
			if current_state == M.STATE_HOSTING then
				netcore.stop_server()
			end
		elseif new_state == M.STATE_IDLE then
			if current_state == M.STATE_CONNECTING or current_state == M.STATE_CONNECTED then
				netcore.stop_client()
			elseif current_state == M.STATE_HOSTING then
				netcore.stop_server()
			end	
		end

		current_state = new_state
		broadcast.send(M.MSG_STATE_CHANGED)
	end
end

local function on_connection_changed(is_connected)
	if is_connected then
		if current_state == M.STATE_CONNECTING then
			change_state_to(M.STATE_CONNECTED)
		end
		if current_state == M.STATE_CONNECTED then
			TEMP_printed_update = false
			print("now connected, p2p set to nil!")
			p2p = nil
		end
	else
		if current_state == M.STATE_CONNECTING or current_state == M.STATE_CONNECTED or current_state == M.STATE_HOSTING then
			change_state_to(M.STATE_IDLE)
		end
	end
end

local function on_failed_connect(reason)
	if current_state == M.STATE_CONNECTING then
		notify.notify(reason)
		change_state_to(M.STATE_IDLE)
	end
end

local function on_local_host_found(ip, port)
	local_host_info = 
	{
		ip=ip,
	}
	TEMP_printed_update = false
	print("local host found, p2p set to nil!")
	p2p = nil
	broadcast.send(M.MSG_LOCAL_HOST_FOUND, local_host_info)	
end

function M.init()
	netcore.register_connection_change_cb(on_connection_changed)
end

function M.final()
	change_state_to(M.STATE_FINAL)
	p2p = nil
end

function M.update()
	if p2p then
		if not TEMP_printed_update then
			print("P2P updating!")
		end
		p2p.update()
	end
end

function M.save()
end

function M.load(profile)
end

function M.start_host(port)
	port = port or DEFAULT_HOST_PORT

	M.disconnect()
	change_state_to(M.STATE_HOSTING)

	TEMP_printed_update = false
	print("starting host, p2p broadcasting!")
	local_host_info = nil
	p2p = p2p_discovery.create(DISCOVERY_PORT)
	p2p.broadcast(get_broadcast_name())
	
	netcore.start_server(port)	
end

function M.connect_to_host(ip, port)
	M.disconnect()
	notify.notify("CONNECT NYI")
end

function M.connect_to_local_host()
	M.disconnect()
	if local_host_info then
		local ip = local_host_info.ip
		local_host_info = nil

		change_state_to(M.STATE_CONNECTING)
		netcore.start_client(ip, DEFAULT_HOST_PORT, on_failed_connect)
	end
end

function M.disconnect()
	netcore.stop_client()
	netcore.stop_server()
end

function M.find_local_host()
	if current_state == M.STATE_IDLE then
		TEMP_printed_update = false
		print("finding local host, p2p set to discovery!")
		p2p = p2p_discovery.create(DISCOVERY_PORT)
		p2p.listen(get_broadcast_name(), on_local_host_found)
	end
end

function M.get_local_host_info()
	return local_host_info
end

function M.get_current_state()
	return current_state
end

return M