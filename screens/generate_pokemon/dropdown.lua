local gooey = require "gooey.gooey"
local gooey_buttons = require "utils.gooey_buttons"

local M = {}

local active = {active=false}

local function button_click(name, button_id, scroll_id)
	if active.active then return true end
	local button_id = gui.get_node(active[name].button_id)
	local scroll_id = gui.get_node(active[name].scroll_id)
	local b = gui.get_size(button_id)
	local s = gui.get_size(scroll_id)
	s.x = b.x 
	gui.set_size(scroll_id, s)
	gui.set_enabled(scroll_id, true)
	local p = gui.get_position(button_id)
	gui.set_position(scroll_id, p)
	active[name].active = true
	active.active = true
end


local function update_items(item, name)
	local item_id = active[name].item_id
	gui.set_text(item.nodes[item_id], item.data)
end

local function update_list(list, name)
	for i,item in ipairs(list.items) do
		update_items(item, name)
	end
end

local function on_item_selected(list, name)
	local scroll_id = active[list.id].scroll_id
	local button_txt_id = active[list.id].button_txt_id
	for i, entry in pairs(list.items) do
		if entry.index == list.selected_item then
			---pprint(button_txt_id)
			gui.set_text(gui.get_node(button_txt_id), entry.data)
			gui.set_enabled(gui.get_node(scroll_id), false)
			active[list.id].active = false
			active[list.id].selected_item = entry.data
			active.active = false
			if active[list.id].func then active[list.id].func() end
		end
	end
end

local function setup_state(name, button_id, button_txt_id, scroll_id, item_id, action_id, action, func)
	local scroll = gui.get_node(scroll_id)
	local button = gui.get_node(button_id)
	if not active[name] then
		active[name] = {active = false, button_id = button_id, button_txt_id = button_txt_id, scroll_id = scroll_id, item_id = item_id, func=func}
	end
	if gui.pick_node(scroll, action.x, action.y) then
		active[name].scroll_over = true
		if action.pressed then
			active[name].scroll_clicked = true
		end
		if active[name].scroll_clicked and action.released then
			--M.active[name].scroll_clicked = false
		end
	else
		active[name].scroll_over = false
		if action.pressed then
			active[name].scroll_clicked = false
		end
	end

	if gui.pick_node(button, action.x, action.y) then
		active[name].button_over = true
		if action.released then
			active[name].button_released = true
			if active[name].button_pressed then
				active[name].button_clicked = true
			end
		end
		if action.pressed then
			active[name].button_pressed = true
		end
	else
		active[name].button_over = true
		active[name].button_clicked = false
	end
end

function M.on_input(name, button_id, button_txt_id, scroll_id, item_id, data, action_id, action, func)
	setup_state(name, button_id, button_txt_id, scroll_id, item_id, action_id, action, func)
	
	if active[name].active and action_id == hash("touch") and not active[name].scroll_clicked and action.released then
		active[name].active = false
		gui.set_enabled(gui.get_node(scroll_id), false)
	end
	
	local b = gooey.button(button_id, action_id, action, function() button_click(name) end)
	if not active[name].active then
		return false
	end
	if active[name] then
		gooey.dynamic_list(name, scroll_id, item_id, data, action_id, action, function(list) on_item_selected(list) end, function(list) update_list(list, name) end)
	end
	return active[name].active
end

return M