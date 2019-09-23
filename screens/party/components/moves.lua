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

local active_nodes

local pp_buttons = {}
local active_move_lists = {[1]={}, [2]={}}

local function update_pp(pokemon, move)
	local pp_current = gui.get_node("txt_pp_current_" .. move)
	local pp_max = gui.get_node("txt_pp_max_" .. move)

	local current = _pokemon.get_move_pp(pokemon, move)
	if type(current) == "number" then
		local max = _pokemon.get_move_pp_max(pokemon, move)
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
	p.x = p.x + gui.get_text_metrics_from_node(pp_current).width * gui.get_scale(pp_current).x
	p.y = cp.y
	gui.set_position(pp_max, p)
end

local function bind_buttons(nodes, name)
	local minus = {node="btn_minus_" .. name, func=function()
		gameanalytics.addDesignEvent {
			eventId = "Party:PP:Decrease"
		}
		
		local pp = _pokemon.decrease_move_pp(current_pokemon, name)
		storage.set_pokemon_move_pp(_pokemon.get_id(current_pokemon), name, pp)
		update_pp(current_pokemon, name)
	end, refresh=gooey_buttons.minus_button
	}

	local plus = {node="btn_plus_" .. name, func=function()
		gameanalytics.addDesignEvent {
			eventId = "Party:PP:Increase"
		}
		
		local pp = _pokemon.increase_move_pp(current_pokemon, name)
		storage.set_pokemon_move_pp(_pokemon.get_id(current_pokemon), name, pp)
		update_pp(current_pokemon, name)
	end, refresh=gooey_buttons.plus_button
	}

	local move = {node="move_" .. name, func=function()
		gameanalytics.addDesignEvent {
			eventId = "Navigation:MoveInfo",
			value = tracking_id[monarch.top()]
		}
		monarch.show("move_info", {}, {pokemon=current_pokemon, name=name, data=_pokemon.get_moves(current_pokemon)[name]})
	end
	}

	table.insert(pp_buttons, minus)
	table.insert(pp_buttons, plus)
	table.insert(pp_buttons, move)
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

local function update_move_data(move)
	local move_data = _pokemon.get_move_data(current_pokemon, move)
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

	gui.set_text(gui.get_node("move_stats_" .. move), table.concat(move_string, "  ||  "))

	gui.set_text(gui.get_node("name_" .. move), move:upper())
	local type = type_data[move_data.type]
	gui.set_color(gui.get_node("name_" .. move), type.color)
	gui.play_flipbook(gui.get_node("element_" .. move), type.icon)

	update_pp(current_pokemon, move)
end

local function create_move_entries(nodes, index)
	local node_table = {}
	local stencil_node = nodes["pokemon/move/move"]
	gui.set_enabled(stencil_node, true)
	
	local position = gui.get_position(stencil_node)
	for _, entry in pairs(active_move_lists[index].data) do
		local clones = gui.clone_tree(stencil_node)
		
		gui.set_id(clones["move"], "move_" .. entry)
		
		local root = gui.get_node("move_" .. entry)
		active_move_lists[index].root[entry] = root
		gui.set_position(root, position)
		gui.set_id(clones["txt_pp_current"], "txt_pp_current_" .. entry)
		gui.set_id(clones["element"], "element_" .. entry)
		gui.set_id(clones["txt_pp_max"], "txt_pp_max_" .. entry)
		gui.set_id(clones["name"], "name_" .. entry)
		gui.set_id(clones["move_stats"], "move_stats_" .. entry)
		
		gui.set_id(clones["btn_plus"], "btn_plus_" .. entry)
		gui.set_id(clones["btn_minus"], "btn_minus_" .. entry)
		position.y = position.y - 147
		update_move_data(entry)
		bind_buttons(nodes, entry)
	end
	
	gui.set_enabled(stencil_node, false)
end

function M.clear(page)
	for _, node in pairs(active_move_lists[page].root) do
		gui.delete_node(node)
	end
	active_move_lists[page] = {}
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

	pp_buttons = {}
	current_pokemon = pokemon
	active_move_lists[index].data = {}
	active_move_lists[index].root = {}
	local _moves = _pokemon.get_moves(pokemon)
	for _, name in pairs(getKeysSortedByValue(_moves, sort_on_index(a, b))) do
		table.insert(active_move_lists[index].data, name)
	end
	create_move_entries(nodes, index)
end


function M.on_input(action_id, action)
	for _, b in pairs(pp_buttons) do
		gooey.button(b.node, action_id, action, b.func, b.refresh)
	end
	
end

function M.on_message(message_id, message)
	if message_id == hash("refresh_pp") then
		for _, entry in pairs(active_list.data) do
			update_move_data(entry)
		end
	end
end


return M
