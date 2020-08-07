local md5 = require "utils.md5"
local netcore = require "pokedex.network.netcore"
local settings = require "pokedex.settings"
local broadcast = require "utils.broadcast"

local net_groups_settings = nil

local M = {}

M.MSG_GROUPS_CHANGED = hash("net_groups_groups_changed")

local function generate_id()
	local m = md5.new()
	m:update(tostring(socket.gettime()))
	return md5.tohex(m:finish()):sub(1, 8)
end

function M.init()
	net_groups_settings = settings.get("net_groups") or {}
	settings.set("net_groups", net_groups_settings)
	
	if not net_groups_settings.server_groups then
		net_groups_settings.server_groups = {}
	end
end

function M.add_group(group_name)
	local id = generate_id()
	local new_group = 
	{
		name = group_name,
		last_used_time = socket.gettime(),
	}

	net_groups_settings.server_groups[id] = new_group
	settings.save()
	
	broadcast.send(M.MSG_GROUPS_CHANGED)

	return id
end

function M.delete_group(group_id)
	if netcore.get_current_state == netcore.STATE_SERVING and netcore.get_server_id() == group_id then
		netcore.stop_server()
	end

	if net_groups_settings.default_group_id == group_id then
		net_groups_settings.default_group_id = nil
	end
	
	net_groups_settings.server_groups[group_id] = nil
	settings.save()
	
	broadcast.send(M.MSG_GROUPS_CHANGED)
end

function M.start_server(group_id, port)
	local group = net_groups_settings.server_groups[group_id]
	if group then
		group.last_used_time = socket.gettime()
		settings.save()

		broadcast.send(M.MSG_GROUPS_CHANGED)
		netcore.start_server(group_id, group.name, port)		
	end
	
end

function M.get_group_name(group_id)
	local group = net_groups_settings.server_groups[group_id]
	return group and group.name or nil
end

function M.set_default_group_id(group_id)
	if net_groups_settings.server_groups[group_id] and net_groups_settings.default_group_id ~= group_id then
		net_groups_settings.default_group_id = group_id
		settings.save()
	end
end

function M.get_default_group_id()
	return net_groups_settings.default_group_id
end

function M.get_group_ids()
	local ret = {}
	for k,_ in pairs(net_groups_settings.server_groups) do
		table.insert(ret, k)
	end

	-- by default sort by last used time. this would be easy enough to change around.
	table.sort(ret, function(a,b) return net_groups_settings.server_groups[a].last_used_time > net_groups_settings.server_groups[b].last_used_time end)
	
	return ret
end

return M