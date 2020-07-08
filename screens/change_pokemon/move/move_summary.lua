local moves = require "pokedex.moves"
local type_data = require "utils.type_data"
local _pokemon = require "pokedex.pokemon"
local gui_utils = require "utils.gui"
local gooey = require "gooey.gooey"

local M = {}

local function join_table(title, T, sep)
	if T then
		return title .. table.concat(T, sep)
	end
	return "-"
end

function M.get_size(str_node_prefix)
	return gui.get_size(gui.get_node(str_node_prefix .. "/background"))
end

function M.setup_move(str_node_prefix, pokemon, move_name)

	local move_data = nil
	if move_name ~= nil then
		-- NOTE: We could get just the flat move data here and not make use of the Pokemon data.
		-- But the Pokemon get_move_data function returns data in a different (nicer) API, is used
		-- by the move_info.gui_script (on which this component is based), and it also is kinda
		-- nice to see what kind of bonus damage you'd get.
		move_data = _pokemon.get_move_data(pokemon, move_name)
	end
	local is_valid = move_data ~= nil
	
	gui.set_enabled(gui.get_node(str_node_prefix .. "/root"), is_valid)
	
	if is_valid then

		-- NOTE: This code was in large part stolen from move_info.gui_script, which the move summary was based on. It has a similar general layout
		-- but is more compressed to fit 2 on a screen better, and since it fits 2 on a screen we split it out into its own component

		-- TODO: This does not quite fit long descriptions, see Acid Spray
		
		local node_name = gui.get_node(str_node_prefix .. "/txt_name")
		local node_desc = gui.get_node(str_node_prefix .. "/txt_desc")
		local node_time = gui.get_node(str_node_prefix .. "/txt_time")
		local node_duration = gui.get_node(str_node_prefix .. "/txt_duration")
		local node_range = gui.get_node(str_node_prefix .. "/txt_range")
		local node_move_power = gui.get_node(str_node_prefix .. "/txt_move_power")
		local node_type = gui.get_node(str_node_prefix .. "/txt_type")
		local node_icon = gui.get_node(str_node_prefix .. "/icon_type")
		local node_pp = gui.get_node(str_node_prefix .. "/txt_pp")
		local node_dmg = gui.get_node(str_node_prefix .. "/txt_dmg")

		gui.set_text(node_name, move_name)
		gui.set_text(node_desc, move_data.description)
		gui.set_text(node_time, move_data.time)
		gui.set_text(node_duration, move_data.duration)
		gui.set_text(node_range, move_data.range or "")
		gui.set_text(node_move_power, join_table("", move_data.power, "/"))
		gui.set_text(node_pp, moves.get_move_pp(move_name))
		gui.set_text(node_type, move_data.type)
		gui.set_text(node_dmg, move_data.damage or "-")

		gui_utils.scale_text_to_fit_size(node_name)
		gui_utils.scale_text_to_fit_size(node_desc)
		gui_utils.scale_text_to_fit_size(node_time)
		gui_utils.scale_text_to_fit_size(node_duration)
		gui_utils.scale_text_to_fit_size(node_range)
		gui_utils.scale_text_to_fit_size(node_move_power)
		gui_utils.scale_text_to_fit_size(node_type)
		gui_utils.scale_text_to_fit_size(node_pp)
		gui_utils.scale_text_to_fit_size(node_dmg)

		gui.play_flipbook(node_icon, type_data[move_data.type].icon)

		local color = {"lbl_pp", "lbl_dmg", "lbl_time", "lbl_range", "lbl_duration", "background", "lbl_move_power"}
		for _, node_name in pairs(color)do
			local color_name = type_data[move_data.type].color
			local node = gui.get_node(str_node_prefix .. "/" .. node_name)
			gui.set_color(node, color_name)
		end
	end

	return is_valid
end


--[[
local function update_list(list)
	if list.scroll and list.scroll.y ~= 0 then
		gooey.vertical_scrollbar("scrollist/scrollbar/handle", "scrollist/scrollbar/bar").scroll_to(0, list.scroll.y)
	end
	for i,item in ipairs(list.items) do
		if item.data and item.data ~= "" then
			update_listitem(list, item)
		end
	end
end

local function refresh_list(self)
	self.list_items = utils.shallow_copy(self.all_items)
	local list = gooey.dynamic_list("scrollist", "scrollist/scroll_area", "scrollist/btn_item", self.list_items)
	list.scroll_to(0, 0)
	update_list(list)
	gooey.vertical_scrollbar("scrollist/scrollbar/handle", "scrollist/scrollbar/bar").scroll_to(0, 0)
end

local function on_scrolled(self, scrollbar)
	gooey.dynamic_list("scrollist", "scrollist/scroll_area", "scrollist/btn_item", self.list_items).scroll_to(0, scrollbar.scroll.y)
end
--]]

function M.on_input(str_node_prefix, action_id, action)
	-- TODO: Figure out
	--gooey.vertical_static_list(list_id, stencil_id, item_ids, action_id, action)

	--[[
	local list = gooey.dynamic_list("scrollist", "scrollist/scroll_area", "scrollist/btn_item", self.list_items, action_id, action, function(item) on_item_selected(self, item) end, update_list)
	if list.max_y and list.max_y > 0 then
		gooey.vertical_scrollbar("scrollist/scrollbar/handle", "scrollist/scrollbar/bar", action_id, action, function(scrollbar) on_scrolled(self, scrollbar) end)
	end
	--]]
	--gooey: function M.vertical_static_list(list_id, stencil_id, item_ids, action_id, action, fn, refresh_fn)
end

return M