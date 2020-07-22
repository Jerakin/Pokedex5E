local tcp_server = require "defnet.tcp_server"
local tcp_client = require "defnet.tcp_client"
local ljson = require "defsave.json"
local profiles = require "pokedex.profiles"
local p2p_discovery = require "defnet.p2p_discovery"
local notify = require "utils.notify"
local broadcast = require "utils.broadcast"

local M = {}

M.MSG_NEARBY_SERVER_FOUND = hash("netcore_nearby_server_found")
M.MSG_STATE_CHANGED = hash("netcore_state_changed")

M.STATE_FINAL = "final"
M.STATE_IDLE = "idle"
M.STATE_SERVING = "serving"
M.STATE_CONNECTING = "connecting"
M.STATE_CONNECTED = "connected"

local current_state = M.STATE_IDLE
local is_listening = false

local server
local version
local p2p
local nearby_server_info = nil
local DEFAULT_HOST_PORT = 9120
local DISCOVERY_PORT = 50120

-- Whether to take any received messages and push them into a queue to be processed during
-- update. Doing this because it's hard to breakpoint debug things inside the server coroutines,
-- but also it's nice to be able to have a spot we can put, say, fake network slowdowns
local QUEUE_RECEIVED_MESSAGES = true

local server_received_message_queue = {}
local client_received_message_queue = {}

local profile_unique_id = nil

local client_data_cbs = {}
local server_data_cbs = {}
local connection_changed_cbs = {}

local server_known_client_info = {}
local server_client_to_unique_id = {}
local server_unique_id_to_client = {}

local client_known_server_info = {}
local client_latest_server_unique_id = nil

local INITIAL_PACKET_KEY = "INITIAL_PACKET"
local RECEIVED_MESSAGE_KEY = "RECEIVED_MESSAGE"

local function get_broadcast_name()
	return "Pokedex5E-" .. version
end

local function is_connected_state(state)
	return state == M.STATE_CONNECTED or state == M.STATE_SERVING
end

local function change_state_to(new_state)
	if new_state ~= current_state and current_state ~= M.STATE_FINAL then

		local old_state_connected = is_connected_state(current_state)
		local new_state_connected = is_connected_state(new_state)
		
		if new_state == M.STATE_SERVING then
			if current_state == M.STATE_CONNECTING or current_state == M.STATE_CONNECTED then
				M.stop_client()
			end
		elseif new_state == M.STATE_CONNECTING then
			if current_state == M.STATE_SERVING then
				M.stop_server()
			end
		elseif new_state == M.STATE_CONNECTED then
			is_listening = false
			p2p.stop()
		elseif new_state == M.STATE_IDLE then
			if current_state == M.STATE_CONNECTING or current_state == M.STATE_CONNECTED then
				M.stop_client()
			elseif current_state == M.STATE_SERVING then
				M.stop_server()
			end	
		end

		current_state = new_state		
		broadcast.send(M.MSG_STATE_CHANGED)

		if old_state_connected ~= new_state_connected then
			for i=1,#connection_changed_cbs do
				connection_changed_cbs[i](conneted)
			end
		end
	end
end

local function fail_client_connect(reason)
	if current_state == M.STATE_CONNECTING then
		notify.notify(reason)
	end
	change_state_to(M.STATE_IDLE)
end

local function on_local_server_found(ip, port)
	nearby_server_info = 
	{
		ip=ip,
	}
	is_listening = false
	p2p.stop()
	broadcast.send(M.MSG_NEARBY_SERVER_FOUND, nearby_server_info)	
end

local function send_to_server_internal(message)
	if client then
		-- TODO after encoding, encrypt
		local encoded = ljson.encode(message) .. "\n"
		client.send(encoded)
	end
end

local function send_to_client_internal(message, client)
	if server then
		-- TODO after encoding, encrypt
		local encoded = ljson.encode(message) .. "\n"
		server.send(encoded, client)
	end
end

local function server_process_received_message(client, message_id)
	local client_unique_id = server_client_to_unique_id[client]
	if client_unique_id then
		local client_info = server_known_client_info[client_unique_id]
		assert(client_info, "server_on_data could not find client info for " .. client_unique_id)

		-- Remove this from the outgoing messages so we don't try to send it again next time we connect
		local this_message
		for i=1,#client_info.outgoing_messages do
			this_message = client_info.outgoing_messages[i]
			if this_message.message_id == message_id then
				table.remove(client_info.outgoing_messages, i)
				break
			end
		end

		if this_message then
			local cb = server_data_cbs[this_message.key].client_confirmed
			if cb then
				cb(client_unique_id, this_message.payload)
			end
		end
	else
		assert(nil, "server_process_received_message could not find client")
	end
end

local function client_process_received_message(message_id)
	if client_latest_server_unique_id then
		local server_info = client_known_server_info[client_latest_server_unique_id]
		assert(server_info, "client_process_received_message could not find server info for " .. client_latest_server_unique_id)

		-- Remove this from the outgoing messages so we don't try to send it again next time we connect
		local this_message
		for i=1,#server_info.outgoing_messages do
			this_message = server_info.outgoing_messages[i]
			if this_message.message_id == message_id then
				table.remove(server_info.outgoing_messages, i)
				break
			end
		end

		if this_message then
			local cb = client_data_cbs[this_message.key].server_confirmed
			if cb then
				cb(this_message.payload)
			end
		end
	else
		assert(nil, "client_process_received_message could not find client")
	end
end

local function server_process_initial_packet(client, packet)
	local server_version = version
	local client_version = "Unknown"
	local client_unique_id = nil

	if packet then
		if packet.version then
			client_version = packet.version
		end
		client_unique_id = packet.unique_id
	end

	if server_version ~= client_version then
		-- This client is the wrong version, tell it to go away
		local initial_response_message = 
		{
			key = INITIAL_PACKET_KEY,
			payload = 
			{
				version = server_version,
			},
			-- no message_id for the initial packet
		}
		send_to_client_internal(initial_response_message, client)
	else
		if client_unique_id then
			local known_client_info = server_known_client_info[client_unique_id]
			if not known_client_info then
				known_client_info =
				{
					latest_sent_message_id = 0,
					latest_received_message_id = 0,
					outgoing_messages = {},
				}
				server_known_client_info[client_unique_id] = known_client_info
			end

			server_unique_id_to_client[client_unique_id] = client		
			server_client_to_unique_id[client] = client_unique_id

			local initial_response_message = 
			{
				key = INITIAL_PACKET_KEY,
				payload = 
				{
					version = version,
					server_unique_id = profile_unique_id,
					latest_received_message_id = known_client_info.latest_received_message_id,
				},
				-- no message_id for the initial packet
			}
			send_to_client_internal(initial_response_message, client)

			-- Also send any queued-up outgoing messages. Note that at this point the client does
			-- not know who we are so they don't know what messages they are missing
			for i=1,#known_client_info.outgoing_messages do
				send_to_client_internal(known_client_info.outgoing_messages[i], client)
			end
		else
			assert(nil, "server_process_initial_packet - client did not send unique_id")
		end
	end	
end

local function client_process_initial_packet_response(packet)
	if packet.version ~= version then
		local server_version = packet.version or "Unknown"
		fail_client_connect("Wrong host version!\nHost's: " .. tostring(server_version) .. ", Ours: " .. tostring(version))
	else
		client_latest_server_unique_id = packet.server_unique_id
		if client_latest_server_unique_id then
			local known_server_info = client_known_server_info[client_latest_server_unique_id]
			if not known_server_info then
				known_server_info =
				{
					latest_sent_message_id = 0,
					latest_received_message_id = 0,
					outgoing_messages = {},
				}
				client_known_server_info[client_latest_server_unique_id] = known_server_info
			end

			-- The server told us what the latest message it received was. Look through the outgoing messages and send
			-- any messages later than that, removing anything it already received.
			local latest_message_received = packet.latest_received_message_id
			local i=1
			while i < #known_server_info.outgoing_messages do
				local this_message = known_server_info.outgoing_messages[i]
				if this_message.message_id > latest_message_received then
					send_to_server_internal(this_message)
					i = i+1
				else
					table.remove(known_server_info.outgoing_messages, i) -- Server already got this
					-- TODO: This message should come with some sort of callback attached
				end
			end

			change_state_to(M.STATE_CONNECTED)
		else
			assert(nil, "client_process_initial_packet_response - server did not send unique_id")
		end
	end
end

local function server_on_data(data, ip, port, client)
	local success = false
	-- TODO before decoding, decrypt	
	if pcall(function() json_data = json.decode(data) end) then
		if type(json_data) == "table" and json_data.key and type(json_data.key) == "string" and json_data.payload then
			if json_data.key == INITIAL_PACKET_KEY then
				server_process_initial_packet(client, json_data.payload)
				success = true
			elseif json_data.key == RECEIVED_MESSAGE_KEY then
				server_process_received_message(client, json_data.payload)
				success = true
			else
				local client_unique_id = server_client_to_unique_id[client]
				if client_unique_id then

					local do_callbacks = true
					
					-- If this message requires ensuring it is sent, we need to send a receipt
					if server_data_cbs[json_data.key].ensure_send then
						local message_id = json_data.message_id
						assert(message_id, "server_on_data client did not send message_id")

						local client_info = server_known_client_info[client_unique_id]
						assert(client_info, "server_on_data could not find client info for " .. client_unique_id)

						if message_id > client_info.latest_received_message_id then
							client_info.latest_received_message_id = message_id
						else
							-- We already got this message, ignore it
							do_callbacks = false
						end

						local received_message = 
						{
							key=RECEIVED_MESSAGE_KEY,
							payload=message_id,
						}
						send_to_client_internal(received_message, client)		
					end

					if do_callbacks then
						-- Call callbacks for this message
						local cb = server_data_cbs[json_data.key].server_received
						if cb then
							cb(client_unique_id, json_data.payload)
						end
					end
					success = true
				else
					-- Client sent us a message despite not being verified. Ignore.
					success = true
				end
			end
		end
	end

	if not success then
		print("Server received unknown data: " .. tostring(data) .. " from client: " .. tostring(ip) .. ", removing it!")
		server.remove_client(client)
	end
end

local function server_on_data_queue(data, ip, port, client)
	table.insert(server_received_message_queue,
	{
		data=data,
		ip=ip,
		port=port,
		client=client,
	})
end

local function client_on_data(data)
	local success = false
	-- TODO before decoding, decrypt
	if pcall(function() json_data = json.decode(data) end) then
		if type(json_data) == "table" and json_data.key and type(json_data.key) == "string" and json_data.payload then
			if json_data.key == INITIAL_PACKET_KEY then
				client_process_initial_packet_response(json_data.payload)
				success = true
			elseif json_data.key == RECEIVED_MESSAGE_KEY then
				client_process_received_message(json_data.payload)
				success = true
			else
				
				local do_callbacks = true
					
				-- If this message requires ensuring it is sent, we need to send a receipt
				if client_data_cbs[json_data.key].ensure_send then					
					local message_id = json_data.message_id
					assert(message_id, "client_on_data server did not send message_id")

					local server_info = client_known_server_info[client_latest_server_unique_id]
					assert(server_info, "client_on_data could not find server info for " .. client_latest_server_unique_id)

					if message_id > server_info.latest_received_message_id then
						server_info.latest_received_message_id = message_id
					else
						-- We already got this message, ignore it
						do_callbacks = false
					end
					
					local received_message = 
					{
						key=RECEIVED_MESSAGE_KEY,
						payload=message_id,
					}
					send_to_server_internal(received_message)
				end

				if do_callbacks then
					-- Call callbacks for this message
					local cb = client_data_cbs[json_data.key].client_received
					if cb then
						cb(json_data.payload)
					end
				end
				success = true
			end
		end
	end

	if not success then
		print("Client received unknown data from server: " .. tostring(data))
		M.stop_client()
	end
end

local function client_on_data_queue(data)
	table.insert(client_received_message_queue,
	{
		data=data,
	})
end

local function server_on_client_connected(ip, port, client)
	print("Client", ip, "connected")
	-- Server will wait for client to send info about its version before deciding the
	-- client if officially recognized. If it sends anything other than the version
	-- message, it'll get booted when it sends a message
end

local function server_on_client_disconnected(ip, port, client)
	print("Client", ip, "disconnected")

	local unique_id = server_client_to_unique_id[client]
	if unique_id then
		server_client_to_unique_id[client] = nil
		server_unique_id_to_client[unique_id] = nil
	end
end

local function set_unique_id(id)
	if profile_unique_id ~= id then
		profile_unique_id = id
		M.stop_server()
		M.stop_client()
	end
end

local function on_active_profile_changed()
	set_unique_id(profiles.get_active_file_name())
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

	p2p = p2p_discovery.create(DISCOVERY_PORT)
	
	on_active_profile_changed()
	profiles.register_active_profile_changed_cb(on_active_profile_changed)
end

function M.final()
	change_state_to(M.STATE_FINAL)
	M.disconnect()
	is_listening = false
	p2p.stop()
	p2p = nil
end

function M.load(profile)
	local data = profile.netcore
	if data ~= nil then
		server_known_client_info=data.server_known_client_info
		client_known_server_info=data.client_known_server_info
		client_latest_server_unique_id=data.client_latest_server_unique_id
	else
		server_known_client_info = {}
		client_known_server_info = {}
		client_latest_server_unique_id = nil
	end
end

function M.save()
	profiles.update(profiles.get_active_slot(),
	{
		netcore =
		{
			server_known_client_info=server_known_client_info,
			client_known_server_info=client_known_server_info,
			client_latest_server_unique_id=client_latest_server_unique_id,
		}
	})
end

function M.register_client_data_callback(key, fn_on_client_received, ensure_send, fn_on_server_confirmed)
	client_data_cbs[key] =
	{
		client_received = fn_on_client_received,
		server_confirmed = fn_on_server_confirmed,
		ensure_send = ensure_send,
	}
end

function M.register_server_data_callback(key, fn_on_server_received, ensure_send, fn_on_client_confirmed)
	server_data_cbs[key] =
	{
		server_received = fn_on_server_received,
		client_confirmed = fn_on_client_confirmed,
		ensure_send = ensure_send,
	}
end

function M.register_connection_change_cb(cb)
	table.insert(connection_changed_cbs, cb)
end

function M.update()
	if p2p then
		p2p.update()
	end
	if server ~= nil then
		server.update()
	end
	if client ~= nil then
		client.update()
	end

	if #server_received_message_queue > 0 then
		local server_queue = server_received_message_queue
		server_received_message_queue = {}
		for i=1,#server_queue do
			local obj = server_queue[i]
			server_on_data(obj.data, obj.ip, obj.port, obj.client)
		end
	end

	if #client_received_message_queue > 0 then
		local client_queue = client_received_message_queue
		client_received_message_queue = {}
		for i=1,#client_queue do
			local obj = client_queue[i]
			client_on_data(obj.data)
		end
	end
end

function M.disconnect()
	M.stop_server()
	M.stop_client()
end

function M.start_server(port)
	port = port or DEFAULT_HOST_PORT
	
	M.disconnect()
	
	client_latest_server_unique_id = profile_unique_id

	is_listening = false
	p2p.broadcast(get_broadcast_name())

	local data_func = QUEUE_RECEIVED_MESSAGES and server_on_data_queue or server_on_data		
	server = tcp_server.create(port, data_func, server_on_client_connected, server_on_client_disconnected)
	server.start()
	
	change_state_to(M.STATE_SERVING)
end

function M.stop_server()
	if server ~= nil then
		server.stop()
		server = nil
		change_state_to(M.STATE_IDLE)
	end
end

local function start_client(server_ip, server_port)
	M.disconnect()

	change_state_to(M.STATE_CONNECTING)

	local data_func = QUEUE_RECEIVED_MESSAGES and client_on_data_queue or client_on_data	
	client = tcp_client.create(server_ip, server_port, data_func, function()
		M.stop_client()			
		if current_state == M.STATE_CONNECTING then
			fail_client_connect("Could not connect! Host may be using\na different version (yours is " .. version .. ").")
		end
	end)

	if client then
		-- Send server a packet to indicate what version of the app we are and what our unique id is
		local initial_packet =
		{
			key = INITIAL_PACKET_KEY,
			payload =
			{
				version = version,
				unique_id = profile_unique_id,
			}
			-- no message_id in initial packet
		}

		send_to_server_internal(initial_packet)
	else
		fail_client_connect("Could not connect! Host\nmay no longer be active.")
	end
end

function M.connect_to_server(ip, port)
	start_client(ip, port)
end

function M.connect_to_nearby_server()
	M.disconnect()
	if nearby_server_info then
		local ip = nearby_server_info.ip
		nearby_server_info = nil

		start_client(ip, DEFAULT_HOST_PORT)
	end
end

function M.stop_client()
	if client ~= nil then
		client.destroy()
		client = nil

		change_state_to(M.STATE_IDLE)
	end
end

function M.send_to_client(key, payload, client_unique_id)
	if server ~= nil then
		if client_unique_id ~= profile_unique_id then
			local known_client_info = server_known_client_info[client_unique_id]
			if known_client_info then
				
				local data =
				{
					key=key,
					payload=payload,
				}

				-- If client requires a receipt, give it an id
				if client_data_cbs[key].ensure_send then
					known_client_info.latest_sent_message_id = known_client_info.latest_sent_message_id+1
					data.message_id = known_client_info.latest_sent_message_id
					table.insert(known_client_info.outgoing_messages, data)
				end

				if server_unique_id_to_client[client_unique_id] then
					send_to_client_internal(data, server_unique_id_to_client[client_unique_id])
				end
			else
				assert(nil, "send_to_client tried to send to a client we had not heard about")
			end
		else
			-- We are the client this is sending to, just call the callbacks - the message was received and confirmed to be received
			local client_cb = client_data_cbs[key].client_received
			if client_cb then
				client_cb(payload)
			end
			local server_cb = client_data_cbs[key].server_confirmed
			if server_cb then
				server_cb(profile_unique_id, payload)
			end
		end
	else
		assert(nil, "send_to_client tried to send to client when not running a server")
	end
end

function M.send_to_server(key, payload)	
	if client_latest_server_unique_id then
		if client_latest_server_unique_id ~= profile_unique_id then
			local server_info = client_known_server_info[client_latest_server_unique_id]
			if server_info then
				
				local data =
				{
					key=key,
					payload=payload,
				}
				
				-- If client requires a receipt, give it an id
				if server_data_cbs[key].ensure_send then
					server_info.latest_sent_message_id = server_info.latest_sent_message_id+1
					data.message_id = server_info.latest_sent_message_id
					table.insert(server_info.outgoing_messages, data)
				end
				
				send_to_server_internal(data)
			else
				assert(nil, "send_to_server attempting to send message to server but no server info is known about that server - something is wrong!")
			end
		else
			-- We ARE the server, just send straight to the callbacks - the message was received and confirmed to be received
			local server_cb = server_data_cbs[key].server_received
			if server_cb then
				server_cb(profile_unique_id, payload)
			end
			local client_cb = server_data_cbs[key].client_confirmed
			if client_cb then
				client_cb(payload)
			end
		end
	end
end

function M.server_get_connected_ids()
	local ret = {}
	if server then
		table.insert(ret, profile_unique_id)
		for _,v in pairs(server_client_to_unique_id) do
			table.insert(ret, v)
		end
	end	
	return ret
end

function M.get_server_id()
	return client_latest_server_unique_id
end

function M.get_known_server_ids()
	local ret = {}
	for k,_ in pairs(client_known_server_info) do
		table.insert(ret, k)
	end
	return ret	
end

function M.get_local_id()
	return profile_unique_id
end

function M.find_nearby_server()
	if current_state == M.STATE_IDLE and not is_listening then
		is_listening = true
		p2p.listen(get_broadcast_name(), on_local_server_found)
	end
end

function M.get_nearby_server_info()
	return nearby_server_info
end

function M.get_current_state()
	return current_state
end

function M.is_connected()
	return is_connected_state(current_state)
end

return M