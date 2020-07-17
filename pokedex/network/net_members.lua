local netcore = require "pokedex.network.netcore"
local broadcast = require "utils.broadcast"
local utils = require "utils.utils"
local profiles = require "pokedex.profiles"

local initialized = false
local server_member_data = {}

local local_member_data = {}
local member_info_by_server = {}

local member_message_cbs = {}

local MEMBER_DATA_KEY = "NET_MEMBERS_DATA"
local MEMBER_MESSAGE_KEY = "NET_MEMBERS_MESSAGE"

local M = {}

M.MEMBERS_CHANGED_MESSAGE = "net_members_members_changed"

local function send_local_data(request_all_members)
	if netcore.is_connected() and local_member_data ~= nil then
		netcore.send_to_server(MEMBER_DATA_KEY,
		{
			member_data=local_member_data,
			request_all_members=request_all_members,
		})
	end
end

local function get_members_list()
	local server_id = netcore.get_server_id()
	return server_id and member_info_by_server[server_id].list or {}
end

local function get_members_id_map()
	local server_id = netcore.get_server_id()
	return server_id and member_info_by_server[server_id].map or {}
end

local function on_connection_change()
	if netcore.is_connected() then
		-- Ensure we know 
		local server_id = netcore.get_server_id()
		if not member_info_by_server[server_id] then
			member_info_by_server[server_id] =
			{
				list = {},
				map = {},
			}
		end
		
		send_local_data(true)
	else
		server_member_clients = {}		
	end	
end

local function active_profile_name_changed()
	local_member_data.name = profiles.get_active_name()
	send_local_data(false)
end

local function on_client_members_data(new_members_data)
	local made_change = false

	local member_map = get_members_id_map()
	local member_list = get_members_list()
	
	for i=1,#new_members_data do
		local new_member_data = new_members_data[i]
		local new_unique_id = new_member_data.unique_id
		local existing_data_index = member_map[new_unique_id]
		if existing_data_index then
			local existing_data = member_list[existing_data_index]
			made_change = utils.deep_merge_into(existing_data, new_member_data) or made_change
		else
			table.insert(member_list, new_member_data)
			member_map[new_unique_id] = #member_list
			made_change = true
		end
	end

	if made_change then
		broadcast.send(M.MEMBERS_CHANGED_MESSAGE)
	end
end

local function on_server_members_data(member_id, payload)
	local member_data = payload.member_data
	member_data.unique_id = member_id -- ensure everyone knows this member's unique id
	server_member_data[member_id] = member_data

	-- Send the new member's data to everyone else
	local all_client_ids = netcore.server_get_connected_ids()
	for i=1,#all_client_ids do
		local this_client_id = all_client_ids[i]
		if this_client_id ~= member_id then
			netcore.send_to_client(MEMBER_DATA_KEY, {member_data}, this_client_id)
		end
	end

	-- If the new member is requesting data about everyone (which they do on first join), get that for them also
	if payload.request_all_members then 
		local other_members_data = {}
		for k,v in pairs(server_member_data) do		
			if k ~= member_id then
				local copy = utils.deep_copy(v)
				copy.unique_id = k
				table.insert(other_members_data, copy)
			end
		end
		if next(other_members_data) then
			netcore.send_to_client(MEMBER_DATA_KEY, other_members_data, member_id)
		end
	end
end

local function on_client_member_message(payload)
	local success = false
	if payload and payload.key and payload.message and payload.from then
		print(" payload.from=", tostring( payload.from))
		local cb =  member_message_cbs[payload.key]
		if cb then
			cb(payload.from, payload.message)
			success = true
		end
	end

	if not success then
		assert(nil, "Unknown member message or key, key=", tostring(payload.key), "message=", tostring(payload.message), "from=", from)
	end
end

local function on_server_member_message(member_id, payload)
	if payload.to and payload.key and payload.message then
		
		local send_payload =
		{
			key=payload.key,
			message=payload.message,
			from=member_id,
		}
		
		netcore.send_to_client(MEMBER_MESSAGE_KEY, send_payload, payload.to)
	end
end

function M.init()
	if not initialized then
		netcore.register_connection_change_cb(on_connection_change)
		netcore.register_client_data_callback(MEMBER_DATA_KEY, on_client_members_data)
		netcore.register_server_data_callback(MEMBER_DATA_KEY, on_server_members_data)
		
		netcore.register_client_data_callback(MEMBER_MESSAGE_KEY, on_client_member_message, true)
		netcore.register_server_data_callback(MEMBER_MESSAGE_KEY, on_server_member_message, true)

		profiles.register_active_name_changed_cb(active_profile_name_changed)
	end
end

function M.load(profile)
	local data = profile.net_members
	if data ~= nil then
		server_member_data = data.server_member_data
		member_info_by_server = data.member_info_by_server
	else
		server_member_data = {}
		member_info_by_server = {}
	end
end

function M.save()
	profiles.update(profiles.get_active_slot(),
	{
		net_members =
		{
			server_member_data=server_member_data,
			member_info_by_server=member_info_by_server,
		}
	})
end

function M.has_other_members()
	return #get_members_list() > 0
end

function M.get_other_members()
	return get_members_list()
end

function M.get_member_name(member_id)
	local index = get_members_id_map()[member_id]
	if index then
		return get_members_list()[index].name
	else
		return "Someone"
	end
end

function M.get_member_key(member_obj)
	return member_obj.unique_id
end

function M.send_message_to_member(key, message, member_key)
	local payload = 
	{
		to=member_key,
		key=key,
		message=message,
	}
	netcore.send_to_server(MEMBER_MESSAGE_KEY, payload)
end

-- cb takes (from_member, message)
function M.register_member_message_callback(key, cb)
	member_message_cbs[key] = cb
end

return M