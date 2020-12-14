-- NOTE: This file was COPIED and MODIFIED from defnet's p2p_discovery. I did this because I didn't feel like forking a new
-- version, making changes in another depot, pulling that all over the place, and eventually submitting a pull request.
-- Any changes are marked with POKEDEX5E_START and POKEDEX5E_END
--- Module to perform peer-to-peer discovery
-- The module can either broadcast it's existence or listen for others

local socket = require "socket.socket"

local M = {}

local STATE_DISCONNECTED = "STATE_DISCONNECTED"
local STATE_BROADCASTING = "STATE_BROADCASTING"
local STATE_LISTENING = "STATE_LISTENING"

local function get_ip()
	for _,network_card in pairs(sys.get_ifaddrs()) do
		if network_card.up and network_card.address then
			pprint(network_card)
			return network_card.address
		end
	end
	return nil
end

--- Create a peer to peer discovery instance
function M.create(port)
	local instance = {}

	local state = STATE_DISCONNECTED

	port = port or 50000

	local listen_co
	local broadcast_co

	--- Start broadcasting a message for others to discover
	-- @param message
	-- @return success
	-- @return error_message
	-- POKEDEX5E_START
	--function instance.broadcast(message)
	function instance.broadcast(message, extra_str)
		-- POKEDEX5E_END
		assert(message, "You must provide a message to broadcast")
		local broadcaster
		local ok, err = pcall(function()
			broadcaster = socket.udp()
			assert(broadcaster:setsockname("*", 0))
			assert(broadcaster:setoption("broadcast", true))
			assert(broadcaster:settimeout(0))
		end)
		if not broadcaster or err then
			print("Error", err)
			return false, err
		end
		-- POKEDEX5E_START
		if extra_str ~= nil then
			message = message .. "|" .. extra_str
		end
		-- POKEDEX5E_END

		-- POKEDEX5E_START
		--print("Broadcasting " .. message .. " on port " .. port)
		-- POKEDEX5E_END
		state = STATE_BROADCASTING
		broadcast_co = coroutine.create(function()
			while state == STATE_BROADCASTING do
				local ok, err = pcall(function()
					broadcaster:sendto(message, "255.255.255.255", port)
				end)
				if err then
					print("DISCONNECTED")
					state = STATE_DISCONNECTED
				else
					coroutine.yield()
				end
			end
			udp_broadcast:close()
			broadcast_co = nil
		end)
		return coroutine.resume(broadcast_co)
	end

	--- Start listening for a broadcasting server
	-- @param message The message to listen for
	-- @param callback Function to call when a broadcasting server has been found. The function
	-- must accept the broadcasting server's IP and port as arguments.
	-- @return success
	-- @return error_message
	function instance.listen(message, callback)
		assert(message, "You must provide a message to listen for")
		local listener
		local ok, err = pcall(function()
			listener = socket.udp()
			assert(listener:setsockname("*", port))
		end)
		if not listener then
			print("Error", err)
			return false, err
		end
		-- POKEDEX5E_START
		local extra_msg = message .. "|"
		local extra_msg_len = string.len(extra_msg)
		-- POKEDEX5E_END

		-- POKEDEX5E_START
		--print("Listening for " .. message .. " on port ".. port)
		-- POKEDEX5E_END
		state = STATE_LISTENING
		listen_co = coroutine.create(function()
			while state == STATE_LISTENING do
				-- POKEDEX5E_START
				--listener:settimeout(0)
				listener:settimeout(0.05)
				-- POKEDEX5E_END
				local data, server_ip, server_port = listener:receivefrom()
				if data and data == message then
					callback(server_ip, server_port)
					state = STATE_DISCONNECTED
					break
				end
				-- POKEDEX5E_START
				if string.sub(data, 1, extra_msg_len) == extra_msg then
					local extra = string.sub(data, extra_msg_len+1)
					callback(server_ip, server_port, extra)
					state = STATE_DISCONNECTED
					break
				end
				-- POKEDEX5E_END
				--print("listening")
				coroutine.yield()
			end
			listen_co = nil
		end)
		return coroutine.resume(listen_co)
	end

	--- Stop broadcasting or listening
	function instance.stop()
		state = STATE_DISCONNECTED
	end

	function instance.update()
		if broadcast_co then
			if coroutine.status(broadcast_co) == "suspended" then
				coroutine.resume(broadcast_co)
			end
		elseif listen_co then
			if coroutine.status(listen_co) == "suspended" then
				coroutine.resume(listen_co)
			end
		end
	end

	return instance
end


return M