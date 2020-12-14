local gooey = require "gooey.gooey"
local gooey_buttons = require "utils.gooey_buttons"
local gooey_scrolling_list = require "utils.gooey_scrolling_list"
local messages = require "utils.messages"

local M = {}

local active = {active=false}

local function button_click(data)
	if active.active then return true end
	
	local node_scroll_bg = gui.get_node(data.scroll_bg_id)
	local node_button = gui.get_node(data.button_id)
	
	local b = gui.get_size(node_button)
	local s = gui.get_size(node_scroll_bg)
	s.x = b.x 
	gui.set_size(node_scroll_bg, s)
	local n = gui.get_node("scroll_selection")
	local s2 = gui.get_size(n)
	s2.x = s.x
	gui.set_size(n, s2)
	
	gui.set_position(gui.get_node("offset"), vmath.vector3(s.x*0.5, 0, 0))
	gui.set_enabled(node_scroll_bg, true)
	local p = gui.get_screen_position(node_button)
	p.y = p.y - b.y * 0.5
	local size = gui.get_size(node_button)
	gui.set_screen_position(node_scroll_bg, p)

	active[data.name].active = true
	active.active = true
	active.name = data.name
end


local function update_item(data, list, item)
	local item_id = data.item_id
	gui.set_text(item.nodes[item_id], item.data:upper())
end

local function on_item_selected(data, list)
	local scroll_bg_id = data.scroll_bg_id
	local button_txt_id = data.button_txt_id
	for i, entry in pairs(list.items) do
		if entry.data and entry.index == list.selected_item then
			gui.set_text(gui.get_node(button_txt_id), entry.data:upper())
			gui.set_enabled(gui.get_node(scroll_bg_id), false)
			active[data.name].active = false
			active[data.name].selected_item = entry.data
			active.active = false
			if data.select_func then data.select_func() end
		end
	end
end

local function setup_state(data, action)
	if not active[data.name] then
		active[data.name] = {active = false, data = data}
	end
	local active_obj = active[data.name]
	
	local scroll = gui.get_node(data.scroll_id)
	local button = gui.get_node(data.button_id)
	
	if gui.pick_node(scroll, action.x, action.y) then
		if action.pressed and active_obj.active then
			active_obj.scroll_clicked = true
		end

	else
		if action.pressed then
			active_obj.scroll_clicked = false
		end
	end

	if gui.pick_node(button, action.x, action.y) then
		active_obj.button_over = true
		if action.released then
			if active_obj.button_pressed then
				active_obj.button_clicked = true
			end
		end
		if action.pressed then
			active_obj.button_pressed = true
		end
	else
		active_obj.button_over = false
		active_obj.button_clicked = false
	end
end

function M.final()
	active = {active=false}
end



local DROPDOWN = {}

function DROPDOWN.on_input(data, list_items, action_id, action)
	setup_state(data, action)
	local active_obj = active[data.name]

	if active_obj.active and not active_obj.scroll_clicked and action_id== messages.TOUCH and action.released and not active_obj.button_over then
		active_obj.active = false
		active.active = false
		gui.set_enabled(gui.get_node(data.scroll_bg_id), false)
	end
	
	local b = gooey.button(data.button_id, action_id, action, function() 
		if active.name ~= data.name then
			data.scrolling_list.scroll_to_start(list_items)
		end
		button_click(data) end)
	if not active_obj.active then
		return false
	end
	if active_obj.active then
		data.scrolling_list.on_input(list_items, action_id, action)
	end
	return active_obj.active
end



function M.create(name, button_id, button_txt_id, scroll_id, scroll_bg_id, item_id, select_func)
	local data =
	{
		name = name,
		button_id = button_id,
		button_txt_id = button_txt_id,
		select_func = select_func,
		scroll_id = scroll_id,
		scroll_bg_id = scroll_bg_id,
		select_func = select_func,
		item_id = item_id,
	}
	data.scrolling_list = gooey_scrolling_list.create_vertical_dynamic(
		name,
		scroll_id,
		item_id,
		"handle",
		"bar",
		"visual",
		function(list, item) update_item(data, list, item) end,
		function(list) on_item_selected(data, list) end,
		{
			allow_scrollbar_input = false,
		})

	local instance = {}
	for name,fn in pairs(DROPDOWN) do
		instance[name] = function(...) return fn(data, ...) end
	end
	return instance
end

return M