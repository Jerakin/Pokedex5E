local gooey = require "gooey.gooey"
local _pokemon = require "pokedex.pokemon"
local storage = require "pokedex.storage"
local party_utils = require "screens.party.utils"
local type_data = require "utils.type_data"
local gui_colors = require "utils.gui_colors"
local gooey_buttons = require "utils.gooey_buttons"
local monarch = require "monarch.monarch"
local tracking_id = require "utils.tracking_id"

local M = {}

local current_pokemon

local active_list = {}

local active_nodes

local pp_buttons = {}
local current_index

local function update_pp(nodes, pokemon, name)
	local pp_current = nodes[hash("txt_pp_current")]
	local pp_max = nodes[hash("txt_pp_max")]

	local current = _pokemon.get_move_pp(pokemon, name)
	if type(current) == "number" then
		local max = _pokemon.get_move_pp_max(pokemon, name)
		gui.set_text(pp_current, current)
		gui.set_text(pp_max, "/" .. max)
		if current == 0 then
			gui.set_color(pp_current, gui_colors.RED)
		elseif current < max then
			gui.set_color(pp_current, gui_colors.RED)
		else
			gui.set_color(pp_current, gui_colors.GREEN)
		end
	else
		gui.set_text(pp_current, "")
		gui.set_text(pp_max, string.sub(current, 1, 5) .. ".")
	end
	
	local p = gui.get_position(pp_current)
	local cp = gui.get_position(pp_max)
	p.x = p.x + gui.get_text_metrics_from_node(pp_current).width
	p.y = cp.y
	gui.set_position(pp_max, p)
end


local function update_listitem(list, item)
	local move_data = _pokemon.get_move_data(current_pokemon, item.data)
	local move_string = {}
	
	if move_data.AB then
		if move_data.AB >= 0 then
			table.insert(move_string, "AB: +" .. move_data.AB)
		else
			table.insert(move_string, "AB: " .. move_data.AB)
		end
	end
	
	if move_data.save_dc then
		table.insert(move_string, "DC: " .. move_data.save_dc)
	end

	if move_data.damage then
		table.insert(move_string, move_data.damage)
	end

	if move_data.range then
		table.insert(move_string, move_data.range)
	end
	
	if move_data.duration then
		table.insert(move_string, move_data.duration)
	end

	gui.set_text(item.nodes[hash("move_stats")], table.concat(move_string, "  ||  "))

	gui.set_text(item.nodes[hash("name")], item.data:upper())
	local type = type_data[move_data.type]
	gui.set_color(item.nodes[hash("name")], type.color)
	gui.play_flipbook(item.nodes[hash("element")], type.icon)
	
	update_pp(item.nodes, current_pokemon, item.data)
end

local function update_pp_buttons(nodes, name)
	local m = {node=name .. "btn_minus", func=function()
		gameanalytics.addDesignEvent {
			eventId = "Party:PP:Decrease"
		}
		
		local pp = _pokemon.decrease_move_pp(current_pokemon, name)
		storage.set_pokemon_move_pp(_pokemon.get_id(current_pokemon), name, pp)
		update_pp(nodes, current_pokemon, name)
	end, refresh=gooey_buttons.minus_button
	}

	local p = {node=name .. "btn_plus", func=function()
		gameanalytics.addDesignEvent {
			eventId = "Party:PP:Increase"
		}
		
		local pp = _pokemon.increase_move_pp(current_pokemon, name)
		storage.set_pokemon_move_pp(_pokemon.get_id(current_pokemon), name, pp)
		update_pp(nodes, current_pokemon, name)
	end, refresh=gooey_buttons.plus_button
	}
	table.insert(pp_buttons, m)
	table.insert(pp_buttons, p)
end

local function update_list(list)
	pp_buttons={}

	for i,item in ipairs(list.items) do
		if item.data then
			update_listitem(list, item)
			gui.set_id(item.nodes[hash("btn_minus")], item.data .. "btn_minus")
			gui.set_id(item.nodes[hash("btn_plus")], item.data .. "btn_plus")
			update_pp_buttons(item.nodes, item.data)
		end
	end
end

local function on_item_selected(list)
	for i,item in ipairs(list.items) do
		if item.data and item.index == list.selected_item then
			gameanalytics.addDesignEvent {
				eventId = "Navigation:MoveInfo",
				value = tracking_id[monarch.top()]
			}
			monarch.show("move_info", {}, {pokemon=current_pokemon, name=item.data, data=_pokemon.get_moves(current_pokemon)[item.data]})
		end
	end
end


local function getKeysSortedByValue(tbl, sortFunction)
	local keys = {}
	for key in pairs(tbl) do
		table.insert(keys, key)
	end

	table.sort(keys, function(a, b)
		return sortFunction(tbl[a], tbl[b])
	end)

	return keys
end

local function sort_on_index(a, b)
	return function(a, b) return a.index < b.index end
end

function M.create(nodes, pokemon, index)
	if pokemon == nil then
		local e = string.format("Moves initated with nil\n\n%s", debug.traceback())
		gameanalytics.addErrorEvent {
			severity = "Critical",
			message = e
		}
		log.error(e)
	end
	active_list = {}
	pp_buttons = {}
	current_index = index
	current_pokemon = pokemon
	active_list.data = {}
	local _moves = _pokemon.get_moves(pokemon)
	for _, name in pairs(getKeysSortedByValue(_moves, sort_on_index(a, b))) do
		table.insert(active_list.data, name)
	end
	update_list(gooey.dynamic_list("moves", "stencil" .. current_index, "item" .. current_index, active_list.data))
end


function M.on_input(action_id, action)
	if next(active_list) ~= nil then
		gooey.dynamic_list("moves", "stencil" .. current_index, "item" .. current_index, active_list.data, action_id, action, on_item_selected, update_list)
	end
	for _, b in pairs(pp_buttons) do
		gooey.button(b.node, action_id, action, b.func, b.refresh)
	end
end


return M
