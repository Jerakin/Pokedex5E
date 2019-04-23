local items = require "pokedex.items"
local feats = require "pokedex.feats"
local pokedex = require "pokedex.pokedex"
local moves = require "pokedex.moves"

local gooey = require "gooey.gooey"

local M = {}

local lists = {MOVES={}, FEATS={}, ABILITIES={}, TM={}, ITEMS={}}

local active_list = {list={}}

local function update_listitem(list, item)
	gui.set_text(item.nodes["txt_item"], tostring(item.data or "-"):upper())
	if item.index == list.selected_item then
		selected_item = item.data
	end
end

local function update_list(list)
	gooey.vertical_scrollbar("scrollbar/handle", "scrollbar/bar").scroll_to(0, list.scroll.y)
	for i,item in ipairs(list.items) do
		update_listitem(list, item)
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

local function show_tm(item)
	print(item)
end

local function show_move(item)
	print(item)
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
	
	lists.ITEMS.list = items.get_list()
	lists.ITEMS.func = show_item
end


function M.activate(list)
	active_list = lists[list]
	gooey.vertical_scrollbar("scrollbar/handle", "scrollbar/bar").scroll_to(0, 0)
	gooey.dynamic_list("scroll", "scrollist", "btn_item", active_list.list).scroll_to(0, 0)
end





return M