local p2p_discovery = require "defnet.p2p_discovery"
local tcp_server = require "defnet.tcp_server"
local tcp_client = require "defnet.tcp_client"
local ljson = require "defsave.json"
local notify = require "utils.notify"

local p2p
local server
local version

local BROADCAST_PORT = 50000

local profile_unique_id = nil

local client_data_cbs = {}
local server_data_cbs = {}
local connection_changed_cbs = {}

local server_known_client_info = {}
local server_client_to_unique_id = {}

local client_known_server_info = {}
local client_current_server_unique_id = nil

local CLIENT_NOT_CONNECTED = 0
local CLIENT_VERIFYING     = 1
local CLIENT_CONNECTED     = 2
local client_connection_status = CLIENT_NOT_CONNECTED

local INITIAL_PACKET_KEY = "INITIAL_PACKET"
local RECEIVED_MESSAGE_KEY = "RECEIVED_MESSAGE"

local M = {}

local function get_broadcast_name()
	return "Pokedex5E-" .. version
end

local function send_to_server_internal(message)
	-- TODO after encoding, encrypt
	local encoded = ljson.encode(message) .. "\n"
	client.send(encoded)
end

local function send_to_client_internal(message, client)
	-- TODO after encoding, encrypt
	local encoded = ljson.encode(message) .. "\n"
	server.send(encoded, client)
end

local function server_process_received_message(client, message_id)
	local client_unique_id = server_client_to_unique_id[client]
	if client_unique_id then
		local client_info = server_known_client_info[client_unique_id]
		assert(client_info, "server_on_data could not find client info for " .. client_unique_id)

		-- Remove this from the outgoing messages so we don't try to send it again next time we connect
		local this_message
		while i < #client_info.outgoing_messages do
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
	if client_current_server_unique_id then
		local server_info = client_known_server_info[client_current_server_unique_id]
		assert(server_info, "client_process_received_message could not find server info for " .. client_current_server_unique_id)

		-- Remove this from the outgoing messages so we don't try to send it again next time we connect
		local this_message
		while i < #server_info.outgoing_messages do
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
		server.remove_client(client)
		M.stop_client()
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

			known_client_info.client = client		
			server_client_to_unique_id[client] = client_unique_id

			local initial_response_message = 
			{
				key = INITIAL_PACKET_KEY,
				payload = 
				{
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
	client_current_server_unique_id = packet.server_unique_id
	if client_current_server_unique_id then
		local known_server_info = client_known_server_info[client_current_server_unique_id]
		if not known_server_info then
			known_server_info =
			{
				latest_sent_message_id = 0,
				latest_received_message_id = 0,
				outgoing_messages = {},
			}
			client_known_server_info[client_current_server_unique_id] = known_server_info
		end

		client_connection_status = CLIENT_CONNECTED
		for i=1,#connection_changed_cbs do
			connection_changed_cbs[i](true)
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
	else
		assert(nil, "client_process_initial_packet_response - server did not send unique_id")
	end
end

local function server_on_data(data, ip, port, client)
	local success = false
	-- TODO before decoding, decrypt	
	if pcall(function() json_data = json.decode(data) end) then
		if type(json_data) == "table" and json_data.key and type(json_data.key) == "string" and json_data.payload then
			if json_data.key == INITIAL_PACKET_KEY then
				server_process_initial_packet(client, json_data.payload)
			elseif json_data.key == RECEIVED_MESSAGE_KEY then
				server_process_received_message(client, json_data.payload)
			else
				local client_unique_id = server_client_to_unique_id[client]
				if client_unique_id then

					local do_callbacks = true
					
					-- If this message requires a message receipt, send one
					if server_data_cbs[json_data.key].client_confirmed then
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
							cb(client, json_data.payload)
							success = true
						end
					end
				else
					-- Client sent us a message despite not being verified. Tell them to go away.
					server.remove_client(client)
				end
			end
		end
	end

	if not success then
		print("Server received unknown data: " .. tostring(data) .. " from client: " .. ip)
	end
end

local function client_on_data(data)
	local success = false
	-- TODO before decoding, decrypt
	if pcall(function() json_data = json.decode(data) end) then
		if type(json_data) == "table" and json_data.key and type(json_data.key) == "string" and json_data.payload then
			if json_data.key == INITIAL_PACKET_KEY then
				client_process_initial_packet_response(json_data.payload)
			elseif json_data.key == RECEIVED_MESSAGE_KEY then
				client_process_received_message(json_data.payload)
			else
				
				local do_callbacks = true
					
				-- If this message requires a message receipt, send one
				if client_data_cbs[json_data.key].server_confirmed then					
					local message_id = json_data.message_id
					assert(message_id, "client_on_data server did not send message_id")

					local server_info = client_known_server_info[client_current_server_unique_id]
					assert(server_info, "client_on_data could not find server info for " .. client_unique_id)

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
						success = true
					end
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
end

local function server_on_client_disconnected(ip, port, client)
	print("Client", ip, "disconnected")

	local unique_id = server_client_to_unique_id[client]
	if unique_id then
		server_client_to_unique_id[client] = nil		
		local known_client_info = server_known_client_info[client_unique_id]
		if known_client_info then
			known_client_info.client = nil
		end
	end
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

function M.set_unique_id(id)
	if profile_unique_id ~= id then
		profile_unique_id = id
		M.stop_server()
		M.stop_client()
	end
end

function M.register_client_data_callback(key, fn_on_client_received, fn_on_server_confirmed)
	client_data_cbs[key] =
	{
		client_received = fn_on_client_received,
		server_confirmed = fn_on_server_confirmed,
	}
end

function M.register_server_data_callback(key, fn_on_server_received, fn_on_client_confirmed)
	server_data_cbs[key] =
	{
		server_received = fn_on_server_received,
		client_confirmed = fn_on_client_confirmed,
	}
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
	
	if server == nil and profile_unique_id then
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
	
	if client == nil and profile_unique_id then
		client = tcp_client.create(server_ip, server_port, client_on_data, function()

			if client_connection_status == CLIENT_VERIFYING then
				notify.notify("Could not connect! Server is probably\nrunning a different version of the app.")
			end
			M.stop_client()
		end)
		
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

		client_connection_status = CLIENT_VERIFYING
		send_to_server_internal(initial_packet)
		return true
	end
	return false
end

function M.stop_client()
	if client ~= nil then
		local previous_status = client_connection_status
		client_connection_status = CLIENT_NOT_CONNECTED
		client.destroy()
		client = nil

		if previous_status == CLIENT_CONNECTED then
			for i=1,#connection_changed_cbs do
				connection_changed_cbs[i](false)
			end
		end
	end
end

function M.send_to_client(key, payload, client_unique_id)
	if server ~= nil then
		local server_cb = client_data_cbs[key].server_confirmed
		if client_unique_id ~= profile_unique_id then
			local known_client_info = server_known_client_info[client_unique_id]
			if known_client_info then
				
				local data =
				{
					key=key,
					payload=payload,
				}

				-- TODO Maybe this should be a flag on registration?
				-- If server requires confirmation of this message, let's track it
				if server_cb then
					known_client_info.latest_sent_message_id = known_client_info.latest_sent_message_id+1
					data.message_id = known_client_info.latest_sent_message_id,
					table.insert(known_client_info.outgoing_messages, data)
				end

				if known_client_info.client then
					send_to_client_internal(known_client_info.client, data)
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
			if server_cb then
				server_cb(profile_unique_id, payload)
			end
		end
	else
		assert(nil, "send_to_client tried to send to client when not running a server")
	end
end

function M.send_to_server(key, payload)	
	if client ~= nil then
		local client_cb = server_data_cbs[key].client_confirmed
		if client_current_server_unique_id then
			
			local server_info = client_known_server_info[client_current_server_unique_id]
			if server_info then
				
				local data =
				{
					key=key,
					payload=payload,
				}
				
				-- If client requires confirmation of this message, let's track it
				-- TODO Maybe this should be a flag on registration?
				if client_cb then
					server_info.latest_sent_message_id = server_info.latest_sent_message_id+1
					data.message_id = server_info.latest_sent_message_id,
					table.insert(server_info.outgoing_messages, data)
				end
				
				send_to_server_internal(data)
			else
				assert(nil, "send_to_server attempting to send message to server but no server info is known about that server - something is wrong!")
			end
		else
			assert(nil, "send_to_server attempting to send message to server despite not knowing who the server is - connection must not be set up yet!")
		end
	elseif server ~= nil then
		-- We ARE the server, just send straight to the callbacks - the message was received and confirmed to be received
		local server_cb = server_data_cbs[key].server_received
		if server_cb then
			server_cb(profile_unique_id, payload)
		end
		if client_cb then
			client_cb(payload)
		end
	else
		assert(nil, "send_to_server not connected to anything, cannot send")
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

function M.is_connected()
	return (server ~= nil) or (client ~= nil and client_connection_status == CLIENT_CONNECTED)
end

return M