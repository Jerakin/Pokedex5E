local broadcast = require "utils.broadcast"
local gooey_scrolling_list = require "utils.gooey_scrolling_list"
local net_members = require "pokedex.network.net_members"
local net_member_name = require "pokedex.network.net_member_name"

local selected_member

local function update_item(data, list, item)
	local member_id = item.data.id
	local name = net_member_name.get_name(member_id)

	gui.set_text(item.nodes[data.list_root.."/txt_item"], tostring(name))

	if item.index == list.selected_item then
		selected_member = item.data
	end
end

local function on_item_selected(data, list)
	if data.fn_on_member_chosen then
		for i,item in ipairs(list.items) do
			if item.data and item.index == list.selected_item then
				local member_id = item.data.id
				data.fn_on_member_chosen(member_id)
			end
		end
	end
end

local MEMBER_LIST = {}

function MEMBER_LIST.on_message(data, message_id, message)
	if message_id == net_members.MEMBERS_CHANGED_MESSAGE then
		data.scrolling_list.refresh(net_members.get_other_members())
	end
end

function MEMBER_LIST.on_input(data, action_id, action)
	data.scrolling_list.on_input(net_members.get_other_members(), action_id, action)
end

local M = {}

function M.create(str_list_root, fn_on_member_chosen)
	local data = {}

	data.fn_on_member_chosen = fn_on_member_chosen
	data.list_root = str_list_root
	data.scrolling_list = gooey_scrolling_list.create_vertical_dynamic(str_list_root, str_list_root.."/scroll_area", str_list_root.."/btn_item", str_list_root.."/scrollbar/handle", str_list_root.."/scrollbar/bar", str_list_root.."/scrollbar/visual", function(list, item) update_item(data, list, item) end, function(list) on_item_selected(data, list) end)
	data.scrolling_list.refresh(net_members.get_other_members())

	local instance = {}
	for name,fn in pairs(MEMBER_LIST) do
		instance[name] = function(...) return fn(data, ...) end
	end
	return instance
end

return M