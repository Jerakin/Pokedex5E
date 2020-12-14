local netcore = require "pokedex.network.netcore"
local broadcast = require "utils.broadcast"
local utils = require "utils.utils"
local profiles = require "pokedex.profiles"
local settings = require "pokedex.settings"

local initialized = false
local server_member_data = {}

local active_profile_changing = false
local local_member_data = nil
local member_info_by_server = {}

local member_message_cbs = {}

local MEMBER_DATA_KEY = "NET_MEMBERS_DATA"
local MEMBER_MESSAGE_KEY = "NET_MEMBERS_MESSAGE"

local M = {}

M.MSG_MEMBERS_CHANGED = hash("net_members_members_changed")

local function ensure_server_known(server_id)
	if not member_info_by_server[server_id] then
		member_info_by_server[server_id] =
		{
			list = {},
			map = {},
		}
	end
end

local function send_local_data()
	if not active_profile_changing and netcore.is_connected() then
		ensure_server_known(netcore.get_server_id())
		netcore.send_to_server(MEMBER_DATA_KEY,
		{
			member_data=local_member_data,
		})
	end
end

local function get_members_list()
	if netcore.is_connected() then
		local server_id = netcore.get_server_id()
		ensure_server_known(server_id)
		return member_info_by_server[server_id].list
	end
	return {}
end

local function get_members_id_map()
	if netcore.is_connected() then
		local server_id = netcore.get_server_id()
		ensure_server_known(server_id)
		return member_info_by_server[server_id].map
	end
	return {}
end

local function on_connection_change()
	if netcore.is_connected() then		
		send_local_data()
	else
		server_member_clients = {}		
	end

	broadcast.send(M.MSG_MEMBERS_CHANGED)
end

local function on_client_members_data(new_members_data)
	local made_change = false

	local member_map = get_members_id_map()
	local member_list = get_members_list()

	for i=1,#new_members_data do
		local new_member_data = new_members_data[i]
		local this_id = new_member_data.id
		local existing_data_index = member_map[this_id]
		if existing_data_index then
			local existing_data = member_list[existing_data_index]
			made_change = utils.deep_merge_into(existing_data.data, new_member_data.data) or made_change
		else
			table.insert(member_list, new_member_data)
			member_map[this_id] = #member_list
			made_change = true
		end
	end

	if made_change then
		M.save()
		broadcast.send(M.MSG_MEMBERS_CHANGED)
	end
end

local function on_server_client_connect(client_id)
	local server_id = netcore.get_server_id()
	if not server_member_data[server_id] then
		server_member_data[server_id] = {}
	end	
	
	local other_members_data = {}
	for k,v in pairs(server_member_data[server_id]) do		
		if k ~= client_id then
			table.insert(other_members_data, {id=k, data=v})
		end
	end
	if next(other_members_data) then
		netcore.send_to_client(MEMBER_DATA_KEY, other_members_data, client_id)
	end
end

local function on_server_members_data(member_id, payload)
	local server_id = netcore.get_server_id()
	if not server_member_data[server_id] then
		server_member_data[server_id] = {}
	end
	if not server_member_data[server_id][member_id] then
		server_member_data[server_id][member_id] = {}
	end
	utils.deep_merge_into(server_member_data[server_id][member_id], payload.member_data)
	settings.save()

	-- Send the new member's data to everyone else
	local all_client_ids = netcore.server_get_connected_ids()
	for i=1,#all_client_ids do
		local this_client_id = all_client_ids[i]
		if this_client_id ~= member_id then
			netcore.send_to_client(MEMBER_DATA_KEY, {{id=member_id, data=payload.member_data}}, this_client_id)
		end
	end
end

local function on_client_member_message(payload)
	local success = false
	if payload and payload.key and payload.message and payload.from then
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

local function on_active_profile_changing()
	active_profile_changing = true
end

local function on_active_profile_changed()
	active_profile_changing = false
	send_local_data()
end

function M.init()
	if not initialized then
		netcore.register_connection_change_cb(on_connection_change)
		netcore.register_client_data_callback(MEMBER_DATA_KEY, on_client_members_data)
		netcore.register_server_data_callback(MEMBER_DATA_KEY, on_server_members_data)
		netcore.register_server_client_connect(on_server_client_connect)
		
		netcore.register_client_data_callback(MEMBER_MESSAGE_KEY, on_client_member_message, true)
		netcore.register_server_data_callback(MEMBER_MESSAGE_KEY, on_server_member_message, true)

		local_member_data = {}

		local net_members_settings = settings.get("net_members") or {}
		settings.set("net_members", net_members_settings)
		
		if not net_members_settings.server_member_data then
			net_members_settings.server_member_data = {}
		end
		server_member_data = net_members_settings.server_member_data

		profiles.register_active_profile_changing_cb(on_active_profile_changing)
		profiles.register_active_profile_changed_cb(on_active_profile_changed)
		
		initialized = true
	end
end

function M.load_profile(profile)
	local data = profile.net_members
	if data ~= nil then
		member_info_by_server = data.member_info_by_server
	else
		member_info_by_server = {}
	end
end

function M.save()
	local active_slot = profiles.get_active_slot()
	if active_slot then
		profiles.update(active_slot,
		{
			net_members =
			{
				member_info_by_server=member_info_by_server,
			}
		})
	end
end

function M.is_local_member_host()
	return netcore.get_current_state() == netcore.STATE_SERVING
end

function M.has_any_members()
	return netcore.is_connected()
end

function M.has_other_members()
	return netcore.is_connected() and #get_members_list() > 0
end

function M.get_all_members()
	if netcore.is_connected() then
		local ret = M.get_other_members()
		table.insert(ret, local_member_data)
		return ret
	end
	return {}
end

function M.get_other_members()
	if netcore.is_connected() then
		local list = get_members_list()
		local ret = {}	
		for i=1,#list do
			table.insert(ret, list[i])
		end
		return ret
	end
	return {}
end

function M.update_member_data(key, data)
	assert(type(key) == "string", "Keys for member data cannot be hashes - they must be strings as they are used as keys in a table saved to disk")
	local_member_data[key] = data
	send_local_data()
end

function M.get_member_id(member_obj)
	return member_obj.id
end

function M.get_data_for_member(key, member_id)
	if member_id == nil or member_id == netcore.get_client_profile_id() then
		return local_member_data[key]
	else
		local index = get_members_id_map()[member_id]
		if index then
			local list = get_members_list()
			if not list[index].data then
				list[index].data = {}
			end
			return list[index].data[key]
		end
	end
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