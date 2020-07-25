local gooey = require "gooey.gooey"
local _pokemon = require "pokedex.pokemon"
local storage = require "pokedex.storage"
local party_utils = require "screens.party.utils"
local type_data = require "utils.type_data"
local gui_colors = require "utils.gui_colors"
local gooey_buttons = require "utils.gooey_buttons"
local monarch = require "monarch.monarch"
local scrollhandler = require "screens.party.components.scrollhandler"
local movedex = require "pokedex.moves"
local screens = require "utils.screens"
local messages = require "utils.messages"

local M = {}

local current_pokemon
local current_index
local active_nodes

local pp_buttons = {}
local active_move_lists = {[1]={}, [2]={}}

local function update_pp(pokemon, move)
	local pp_current = gui.get_node("txt_pp_current_" .. current_index .. move)
	local pp_max = gui.get_node("txt_pp_max_" .. current_index .. move)

	local valid_pp_numbers = false
	local dex_pp = movedex.get_move_pp(move)
	if type(dex_pp) == "number" then
		local current = _pokemon.get_move_pp(pokemon, move)
		local max = _pokemon.get_move_pp_max(pokemon, move)
		if type(current) == "number" and type(max) == "number" then
			gui.set_text(pp_current, current)
			gui.set_text(pp_max, "/" .. max)
			if current == 0 then
				gui.set_color(pp_current, gui_colors.RED)
			elseif current < max then
				gui.set_color(pp_current, gui_colors.RED)
			else
				gui.set_color(pp_current, gui_colors.GREEN)
			end
			valid_pp_numbers = true
		end
	end
	
	if not valid_pp_numbers then
		-- Weird state - something with this pp was not a number. This is probably one of the many
		-- edge cases with Struggle, the only move currently with a non-number amount of pp (Unlimited).
		-- Show the text instead as the text we got from the movedex
		gui.set_text(pp_current, "")
		gui.set_text(pp_max, string.sub(dex_pp, 1, 5) .. ".")
	end
	
	local p = gui.get_position(pp_current)
	local cp = gui.get_position(pp_max)
	p.x = p.x + gui.get_text_metrics_from_node(pp_current).width * gui.get_scale(pp_current).x
	p.y = cp.y
	gui.set_position(pp_max, p)

	-- I would like to do this, but completely hiding just 1 of the buttons ends up looking kinda weird.
	-- if would be better if there were some sort of "grayed out" state for buttons, but I can't find one...
	--gui.set_enabled(gui.get_node("btn_minus_" .. current_index .. move), _pokemon.can_decrease_move_pp(pokemon, move))
	--gui.set_enabled(gui.get_node("btn_plus_"  .. current_index .. move), _pokemon.can_increase_move_pp(pokemon, move))
	
	-- ... but it definitely doesn't look good to have buttons that you can NEVER press, so hide those
	if not valid_pp_numbers then
		gui.set_enabled(gui.get_node("btn_minus_" .. current_index .. move), false)
		gui.set_enabled(gui.get_node("btn_plus_"  .. current_index .. move), false)
	end
end

local function bind_buttons(nodes, name)
	local minus = {node="btn_minus_" .. current_index .. name, func=function()
		local pp = _pokemon.decrease_move_pp(current_pokemon, name)
		if pp ~= nil then
			storage.set_pokemon_move_pp(_pokemon.get_id(current_pokemon), name, pp)
			update_pp(current_pokemon, name)
		end			
	end, refresh=gooey_buttons.minus_button
	}

	local plus = {node="btn_plus_" .. current_index .. name, func=function()
		local pp = _pokemon.increase_move_pp(current_pokemon, name)
		if pp ~= nil then
			storage.set_pokemon_move_pp(_pokemon.get_id(current_pokemon), name, pp)
			update_pp(current_pokemon, name)
		end
	end, refresh=gooey_buttons.plus_button
	}

	local move = {node="interaction_area_" .. current_index .. name, func=function()
		monarch.show(screens.MOVE_INFO, {}, {pokemon=current_pokemon, name=name, data=_pokemon.get_moves(current_pokemon)[name]})
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

	gui.set_text(gui.get_node("move_stats_" .. current_index .. move), table.concat(move_string, "  ||  "))

	gui.set_text(gui.get_node("name_" .. current_index .. move), move:upper())
	local type = type_data[move_data.type]
	gui.set_color(gui.get_node("name_" .. current_index .. move), type.color)
	gui.play_flipbook(gui.get_node("element_" .. current_index .. move), type.icon)

	update_pp(current_pokemon, move)
end

local function create_move_entries(nodes, index)
	local node_table = {}
	local stencil_node = nodes["pokemon/move/move"]
	gui.set_enabled(stencil_node, true)
	local distance = gui.get_size(stencil_node).y
	local position = gui.get_position(stencil_node)
	for _, entry in pairs(active_move_lists[index].data) do
		local clones = gui.clone_tree(stencil_node)
		
		gui.set_id(clones["move"], "move_" .. index .. entry)

		local root = gui.get_node("move_" .. index .. entry)
		active_move_lists[index].root[entry] = root
		gui.set_position(root, position)
		gui.set_id(clones["txt_pp_current"], "txt_pp_current_" .. index .. entry)
		gui.set_id(clones["element"], "element_" .. index .. entry)
		gui.set_id(clones["txt_pp_max"], "txt_pp_max_" .. index .. entry)
		gui.set_id(clones["name"], "name_"  .. index.. entry)
		gui.set_id(clones["move_stats"], "move_stats_" .. index .. entry)
		gui.set_id(clones["interaction_area"], "interaction_area_" .. index .. entry)
		
		gui.set_id(clones["btn_plus"], "btn_plus_" .. index .. entry)
		gui.set_id(clones["btn_minus"], "btn_minus_"  .. index.. entry)
		position.y = position.y - distance
		update_move_data(entry, index)
		bind_buttons(nodes, entry)
	end
	scrollhandler.set_max(index, 1, distance * #active_move_lists[index].data)
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
	current_index = index
	pp_buttons = {}
	current_pokemon = pokemon
	active_move_lists[index].data = {}
	active_move_lists[index].root = {}
	local _moves = _pokemon.get_moves(pokemon, {append_known_to_all=true})
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

function M.on_message(message_id, message, index)
	if message_id == messages.REFRESH_PP then
		for _, entry in pairs(active_move_lists[index].data) do
			update_move_data(entry)
		end
	end
end


return M
