local gooey = require "gooey.gooey"
local _pokemon = require "pokedex.pokemon"
local party_utils = require "screens.party.utils"
local type_data = require "utils.type_data"
local gui_colors = require "utils.gui_colors"
local gooey_buttons = require "utils.gooey_buttons"
local monarch = require "monarch.monarch"
local M = {}

local current_pokemon

local active_list = {}

local active_nodes

local pp_buttons = {}


local function update_pp(nodes, pokemon, name)
	local pp_current = nodes[hash("txt_pp_current")]
	local pp_max = nodes[hash("txt_pp_max")]
	
	local current = _pokemon.get_move_pp(pokemon, name) 
	local max = _pokemon.get_move_pp_max(pokemon, name)
	gui.set_text(pp_current, current)
	gui.set_text(pp_max, "/" .. max)
	local p = gui.get_position(pp_current)
	local cp = gui.get_position(pp_max)
	p.x = p.x + gui.get_text_metrics_from_node(pp_current).width
	p.y = cp.y
	gui.set_position(pp_max, p)
	if current == 0 then
		gui.set_color(pp_current, gui_colors.RED)
	elseif current < max then
		gui.set_color(pp_current, gui_colors.RED)
	else
		gui.set_color(pp_current, gui_colors.GREEN)
	end
end


local function update_listitem(list, item)
	if item.data == "" then
		return
	end

	local move_data = _pokemon.get_move_data(current_pokemon, item.data)
	local move_string = ""

	if move_data.damage then
		move_string = move_string .. "AB: " .. move_data.AB
		move_string = move_string ..  move_data.damage
	elseif move_data.save_dc then
		move_string = move_string ..  move_data.save_dc
	end

	if move_data.AB == nil then
		move_string = move_string .. "AB: -"
	end
	move_string = move_string .. move_data.range or ""

	gui.set_text(item.nodes[hash("move_stats")], move_string)

	
	gui.set_text(item.nodes[hash("name")], item.data:upper())
	local type = type_data[move_data.type]
	gui.set_color(item.nodes[hash("name")], type.color)
	gui.play_flipbook(item.nodes[hash("element")], type.icon)
	
	update_pp(item.nodes, current_pokemon, item.data)
end

local function update_pp_buttons(nodes, name)
	local m = {node=name .. "btn_minus", func=function()
		_pokemon.decrease_move_pp(current_pokemon, name)
		update_pp(nodes, current_pokemon, name)
	end, refresh=gooey_buttons.minus_button
	}

	local p = {node=name .. "btn_plus", func=function()
		_pokemon.increase_move_pp(current_pokemon, name)
		update_pp(nodes, current_pokemon, name)
	end, refresh=gooey_buttons.plus_button
	}
	table.insert(pp_buttons, m)
	table.insert(pp_buttons, p)
end

local function update_list(list)
	pp_buttons={}
	for i, item in ipairs(list.items) do
		update_listitem(list, item)
		gui.set_id(item.nodes[hash("btn_minus")], item.data .. "btn_minus")
		gui.set_id(item.nodes[hash("btn_plus")], item.data .. "btn_plus")
		update_pp_buttons(item.nodes, item.data)
	end
end

local function on_item_selected(list)
	for i,item in ipairs(list.items) do
		if item.index == list.selected_item then
			monarch.show("move_info", {}, {pokemon=current_pokemon, name=item.data, data=_pokemon.get_moves(current_pokemon)[item.data]})
		end
	end
end

function M.create(nodes, pokemon)
	active_list = {}
	gui.set_id(nodes["pokemon/move/txt_pp_current"], "txt_pp_current")
	gui.set_id(nodes["pokemon/move/txt_pp_max"], "txt_pp_max")
	gui.set_id(nodes["pokemon/move/lbl_pp"], "lbl_pp")
	gui.set_id(nodes["pokemon/move/move_stats"], "move_stats")
	gui.set_id(nodes["pokemon/move/name"], "name")
	gui.set_id(nodes["pokemon/move/element"], "element")
	gui.set_id(nodes["pokemon/move/pp/btn_minus"], "btn_minus")
	gui.set_id(nodes["pokemon/move/pp/btn_plus"], "btn_plus")

	current_pokemon = pokemon
	active_list.stencil = party_utils.set_id(nodes["pokemon/tab_bg_1"])
	active_list.item = party_utils.set_id(nodes["pokemon/move/move"])

	active_list.data = {}
	for name, _ in pairs(_pokemon.get_moves(pokemon)) do
		table.insert(active_list.data, name)
	end
	update_list(gooey.dynamic_list("moves", active_list.stencil, active_list.item, active_list.data))
end


function M.on_input(action_id, action)
	gooey.dynamic_list("moves", active_list.stencil, active_list.item, active_list.data, action_id, action, on_item_selected, update_list)
	for _, b in pairs(pp_buttons) do
		gooey.button(b.node, action_id, action, b.func, b.refresh)
	end
end


return M
