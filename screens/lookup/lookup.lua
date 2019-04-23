local items = require "pokedex.items"
local feats = require "pokedex.feats"
local pokedex = require "pokedex.pokedex"
local moves = require "pokedex.moves"

local type_data = require "utils.type_data"

local gooey = require "gooey.gooey"

local M = {}

local lists = {MOVES={}, FEATS={}, ABILITIES={}, TM={}, ITEMS={}}

local active_list = {list={}}

local function update_listitem(list, item)
	if active_list.format then
		gui.set_text(item.nodes["txt_item"], active_list.format(tostring(item.data):upper()))
	else
		gui.set_text(item.nodes["txt_item"], item.data:upper())
	end
	if item.index == list.selected_item then
		selected_item = item.data
	end
end

local function update_list(list)
	gooey.vertical_scrollbar("scrollbar/handle", "scrollbar/bar").scroll_to(0, list.scroll.y)
	for i,item in ipairs(list.items) do
		if item.data and item.data ~= "" then
			update_listitem(list, item)
		end
	end
end

local function on_item_selected(list)
	for i,item in ipairs(list.items) do
		if item.index == list.selected_item then
			active_list.func(item.data)
		end
	end
end

local function on_scrolled(scrollbar)
	gooey.dynamic_list("scroll", "scrollist", "btn_item", active_list.list).scroll_to(0, scrollbar.scroll.y)
end

function M.on_input(self, action_id, action)
	if next(active_list) ~= nil then
		local list = gooey.dynamic_list("scroll", "scrollist", "btn_item", active_list.list, action_id, action, on_item_selected, update_list)
		if list.max_y and list.max_y > 0 then
			gooey.vertical_scrollbar("scrollbar/handle", "scrollbar/bar", action_id, action, on_scrolled)
		end
	end
end

local function show_item(item)
	print(item)
end

local function show_feat(item)
	print(item)
end

local function show_ability(item)
	print(item)
end


local function join_table(title, T, sep)
	if T then
		return title .. table.concat(T, sep)
	end
	return "-"
end

local function show_move(item)
	local move_data = moves.get_move_data(item)
	gui.set_text(gui.get_node("move/txt_name"), item)
	gui.set_text(gui.get_node("move/txt_desc"), move_data.Description)
	gui.set_text(gui.get_node("move/txt_time"), move_data["Move Time"])
	gui.set_text(gui.get_node("move/txt_duration"), move_data.Duration)
	gui.set_text(gui.get_node("move/txt_range"), move_data.Range or "")
	gui.set_text(gui.get_node("move/txt_move_power"), join_table("", move_data["Move Power"], "/"))
	gui.set_text(gui.get_node("move/txt_pp"), move_data.PP)
	
	-- Set type name and image and placements
	local type_node = gui.get_node("move/txt_type")
	gui.set_text(type_node, move_data.Type)
	local p = gui.get_position(type_node)
	p.x = p.x + gui.get_text_metrics_from_node(type_node).width * 0.5
	gui.set_position(gui.get_node("move/icon_type"), p)
	gui.play_flipbook(gui.get_node("move/icon_type"), type_data[move_data.Type].icon)

	local color = {"lbl_pp", "lbl_dmg", "lbl_time", "lbl_range", "lbl_duration", "background", "lbl_move_power"}
	for _, node_name in pairs(color)do
		local color_name = type_data[move_data.Type].color
		local node = gui.get_node("move/"..node_name)
		gui.set_color(node, color_name)
	end
end

local function show_tm(item)
	show_move(moves.get_TM(item))
end


local function TM_list()
	local l = {}
	for i=1, 100 do
		table.insert(l, i)
	end
	return l
end

function M.init()
	gooey.dynamic_list("scroll", "scrollist", "btn_item", active_list.list)
	gooey.vertical_scrollbar("scrollbar/handle", "scrollbar/bar")
	lists.MOVES.list = moves.list
	lists.MOVES.func = show_move
	
	lists.FEATS.list = feats.list
	lists.FEATS.func = show_feat
	
	lists.ABILITIES.list = pokedex.ability_list()
	lists.ABILITIES.func = show_ability
	
	lists.TM.list = TM_list()
	lists.TM.func = show_tm
	lists.TM.format = function(move) return move .. " - " .. moves.get_TM(tonumber(move)) end
	lists.ITEMS.list = items.get_list()
	lists.ITEMS.func = show_item
end


function M.activate(list)
	active_list = lists[list]
	gooey.vertical_scrollbar("scrollbar/handle", "scrollbar/bar").scroll_to(0, 0)
	gooey.dynamic_list("scroll", "scrollist", "btn_item", active_list.list).scroll_to(0, 0)
end





return M