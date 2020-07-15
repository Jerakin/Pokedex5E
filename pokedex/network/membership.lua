local validated_connection = require "pokedex.network.validated_connection"
local network = require "pokedex.network"

local server_member_data = {}
local server_member_clients = {}

local external_member_list = {}
local local_member_data = {}

local KEY = "MEMBERSHIP"

local function send_local_data()
	if validated_connection.is_connected() and local_member_data ~= nil then
		network.send_to_server(KEY, local_member_data)
	end
end

local function on_connection_change()
	send_local_data()
end

local function on_client_data(other_members_data)
	external_member_list = other_members_data

	for k,v in pairs(external_member_list) do
		print("We now know about user " .. tostring(k) .. " with name: " .. tostring(v.name))
	end
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
		network.send_to_client(KEY, other_members_data, v)
	end
end

local M = {}

function M.init()
	validated_connection.register_connection_change(on_connection_change)
	network.register_client_callback(KEY, on_client_data)
	network.register_server_callback(KEY, on_server_data)
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