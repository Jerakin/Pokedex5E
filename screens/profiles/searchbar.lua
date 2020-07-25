local gooey = require "gooey.gooey"
local gui_colors = require "utils.gui_colors"
local url = require "utils.url"
local platform = require "utils.platform"

local M = {}

local function starts_with(str, start)
	return string.lower(str):sub(1, #start) == string.lower(start)
end

local function filter_profiles(self, search_string)
	for i=#self.scrolling_data, 1, -1 do
		local profile_index = self.scrolling_data[i]
		if starts_with(self.all_slots[profile_index].name, search_string) then
			table.insert(self.filtered_list, 1, self.scrolling_data[i])
		end
	end
end

function M.filter_list(self, search_string)
	if #search_string > 0 then
		self.filtered_list = {}
		filter_profiles(self, search_string:lower())
	else
		self.filtered_list = self.scrolling_data
	end
	msg.post(url.PROFILES, "search")
end

local function refresh_input(self, input, node_id)
	if input.empty and not input.selected then
		gui.set_text(input.node, "search")
		gui.set_color(input.node, gui_colors.HERO_TEXT_FADED)
	end

	local cursor = gui.get_node("cursor")
	if input.selected then
		if input.empty then
			gui.set_text(self.seach_text, "")
		end
		
		self.scrolling_data = {}

		for index, _ in pairs(self.all_slots) do
			table.insert(self.scrolling_data, index)
		end

		gui.set_enabled(cursor, true)
		gui.set_position(cursor, vmath.vector3(input.total_width, 0, 0))
		gui.cancel_animation(cursor, gui.PROP_COLOR)
		gui.set_color(input.node, gui_colors.HERO_TEXT)
		gui.animate(cursor, gui.PROP_COLOR, vmath.vector4(1,1,1,0), gui.EASING_INSINE, 0.8, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
		M.filter_list(self, input.text .. input.marked_text)
	else
		gui.set_enabled(cursor, false)
		gui.cancel_animation(cursor, gui.PROP_COLOR)
	end
end

local enabled = vmath.vector3(0)
local disabled = vmath.vector3(0, -449, 0)

local function keyboard_toggle(self, toggle)
	local pos = disabled
	if platform.MOBILE_PHONE then
		gui.set_enabled(self.seach_background, false)
		if toggle then
			pos = enabled
			gui.set_enabled(self.seach_background, true)
		end
		gui.set_position(gui.get_node("search"), pos)
	end
end

function M.on_input(self, action_id, action)
	local input = gooey.input("search_text", gui.KEYBOARD_TYPE_DEFAULT, action_id, action, {use_marked_text=false}, function(input)
		refresh_input(self, input, "search_text")
	end)
	if input.enabled then
		if input.selected then
			keyboard_toggle(self, true)
		else
			keyboard_toggle(self, false)
		end
	end
end

return M