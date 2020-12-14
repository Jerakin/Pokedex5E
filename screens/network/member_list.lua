local broadcast = require "utils.broadcast"
local gooey_scrolling_list = require "utils.gooey_scrolling_list"
local net_members = require "pokedex.network.net_members"
local net_member_name = require "pokedex.network.net_member_name"

local function update_item(data, list, item)
	local member_id = item.data.id
	local name = net_member_name.get_name(member_id)

	gui.set_text(item.nodes[data.list_root.."/txt_item"], tostring(name))
end

local function on_item_selected(data, list)
	if data.fn_member_chosen then
		for i,item in ipairs(list.items) do
			if item.data and item.index == list.selected_item then
				local member_id = item.data.id
				data.fn_member_chosen(member_id)
			end
		end
	end
end

local function refresh_list(data)
	data.members = data.show_self and net_members.get_all_members() or net_members.get_other_members()
	data.scrolling_list.refresh(data.members)
end

local MEMBER_LIST = {}

function MEMBER_LIST.on_message(data, message_id, message)
	if message_id == net_members.MSG_MEMBERS_CHANGED then
		refresh_list(data)
	end
end

function MEMBER_LIST.on_input(data, action_id, action)
	data.scrolling_list.on_input(data.members, action_id, action)
end

local M = {}

function M.create(str_list_root, options)
	local data = {}

	data.fn_member_chosen = options.fn_member_chosen
	data.list_root = str_list_root
	data.show_self = options.show_self or false
	data.scrolling_list = gooey_scrolling_list.create_vertical_dynamic(str_list_root, str_list_root.."/scroll_area", str_list_root.."/btn_item", str_list_root.."/scrollbar/handle", str_list_root.."/scrollbar/bar", str_list_root.."/scrollbar/visual", function(list, item) update_item(data, list, item) end, function(list) on_item_selected(data, list) end)
	refresh_list(data)

	local instance = {}
	for name,fn in pairs(MEMBER_LIST) do
		instance[name] = function(...) return fn(data, ...) end
	end
	return instance
end

return M