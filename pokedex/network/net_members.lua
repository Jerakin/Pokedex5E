local netcore = require "pokedex.network.netcore"

local server_member_data = {}
local server_member_clients = {}

local external_member_list = {}
local local_member_data = {}

local KEY = "NET_MEMBERS"

local function send_local_data()
	if netcore.is_connected() and local_member_data ~= nil then
		netcore.send_to_server(KEY, local_member_data)
	end
end

local function on_connection_change()
	send_local_data()

	if not netcore.is_connected() then
		external_member_list = {}
		server_member_clients = {}

		-- TODO send event about member list update
	end
end

local function on_client_data(other_members_data)
	external_member_list = other_members_data

	print("net_members.on_client_data - We got data about other members:")
	for k,v in pairs(external_member_list) do
		print("  " .. tostring(v.name) .. " (" .. tostring(k) .. ")")
	end

	-- TODO send event about member list update
end

local function on_server_data(client, member_data) 
	server_member_clients[member_data.unique_id] = client
	server_member_data[member_data.unique_id] = member_data

	-- Send each member data about everyone but themselves
	for k,v in pairs(server_member_clients) do
		local other_members_data = {}
		for k2,v2 in pairs(server_member_data) do
			if k ~= k2 then
				other_members_data[k2] = v2
			end
		end
		netcore.send_to_client(KEY, other_members_data, v)
	end
end

local M = {}

function M.init()
	netcore.register_connection_change_cb(on_connection_change)
	netcore.register_client_data_callback(KEY, on_client_data)
	netcore.register_server_data_callback(KEY, on_server_data)
end

function M.set_local_member_data(name, unique_id)
	local_member_data =
	{
		name = name,
		unique_id = unique_id,
	}
	send_local_data()
end

return M