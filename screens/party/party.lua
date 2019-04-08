local storage = require "pokedex.storage"
local _pokemon = require "pokedex.pokemon"
local pokedex = require "pokedex.pokedex"
local gui_colors = require "utils.gui_colors"
local button = require "utils.button"
local gooey_buttons = require "utils.gooey_buttons"
local gooey = require "gooey.gooey"
local monarch = require "monarch.monarch"

local party_utils = require "screens.party.utils"
local features = require "screens.party.components.features"
local moves = require "screens.party.components.moves"
local information = require "screens.party.components.information"
local meters = require "screens.party.components.meters"

local M = {}

M.last_active = nil

local active_page = 1

local pokemon_pages = {}

local active_pokemon_id

function M.get_active_id()
	return active_pokemon_id
end

local function activate_tab(nodes, tab_number)
	for i=1, 3 do
		if tab_number == i then
			gui.play_flipbook(nodes["pokemon/tab_" .. i], "common_down")
			gui.set_color(nodes["pokemon/text" .. i], gui_colors.BUTTON_TEXT_PRESSED)
			gui.set_enabled(nodes["pokemon/tab_bg_" .. i], true)
		else
			gui.play_flipbook(nodes["pokemon/tab_" .. i], "common_up")
			gui.set_color(nodes["pokemon/text" .. i], gui_colors.BUTTON_TEXT)
			gui.set_enabled(nodes["pokemon/tab_bg_" .. i], false)
		end
	end
end

local function tab_buttons(nodes)
	button.register(nodes["pokemon/tab_1"], function()
		activate_tab(nodes, 1)
	end)
	button.register(nodes["pokemon/tab_2"], function()
		activate_tab(nodes, 2)
	end)
	button.register(nodes["pokemon/tab_3"], function()
		activate_tab(nodes, 3)
	end)
end


function M.show(id)
	M.last_active = id
	active_pokemon_id = id
	local pokemon = storage.get_copy(id)
	local nodes = pokemon_pages[active_page].nodes
	information.create(nodes, pokemon)
	meters.create(nodes, pokemon)
	moves.create(nodes, pokemon, active_page)
	features.create(nodes, pokemon, active_page)
	
	button.register(nodes["pokemon/exp_bg"], function()
		monarch.show("input", {}, {sender=msg.url(), message="update_exp", allowed_characters="[%d%+%-]", default_text=storage.get_pokemon_exp(id)})
	end)

	button.register(nodes["pokemon/hp_bar_bg"], function()
		monarch.show("input", {}, {sender=msg.url(), message="update_hp", allowed_characters="[%d%+%-]", default_text=storage.get_pokemon_current_hp(id)})
	end)
end

local function reset()
	active_page = 1
	pokemon_pages = {}
	--active_pokemon_id = nil
end

function M.switch_to_slot(index)
	last_active = index
	local pos_index = -1
	local id = storage.list_of_ids_in_inventory()[index]
	if active_pokemon_id == id then
		return
	elseif active_page - index < 0 then
		pos_index = 1
	end
	active_pokemon_id = id
	local old_page = active_page
	active_page = (1-active_page ) + 2
	local active = pokemon_pages[old_page].nodes["pokemon/root"]
	local new = pokemon_pages[active_page].nodes["pokemon/root"]

	M.show(id)
	gui.set_position(new, vmath.vector3(720*pos_index, 0, 0))
	
	gui.animate(active, "position.x", (-1*pos_index)*720, gui.EASING_INSINE, 0.5, 0, function()
		gui.set_enabled(active, false)
	end)
	gui.set_enabled(new, true)
	gui.animate(new, "position.x", 0, gui.EASING_INSINE, 0.5, 0, function()
		features.clear(old_page)
		
	end)
end

local function set_ids(nodes, index)
	gui.set_id(nodes["pokemon/move/txt_pp_current"], "txt_pp_current")
	gui.set_id(nodes["pokemon/move/txt_pp_max"], "txt_pp_max")
	gui.set_id(nodes["pokemon/move/lbl_pp"], "lbl_pp")
	gui.set_id(nodes["pokemon/move/move_stats"], "move_stats")
	gui.set_id(nodes["pokemon/move/name"], "name")
	gui.set_id(nodes["pokemon/move/element"], "element")
	gui.set_id(nodes["pokemon/move/pp/btn_minus"], "btn_minus")
	gui.set_id(nodes["pokemon/move/pp/btn_plus"], "btn_plus")
	gui.set_id(nodes["pokemon/tab_bg_1"], "stencil" .. index)
	gui.set_id(nodes["pokemon/move/move"], "item" .. index)
end

function M.create()
	reset()
	local p = gui.get_position(gui.get_node("pokemon/tab_bg_1"))
	gui.set_position(gui.get_node("pokemon/tab_bg_2"), p)
	gui.set_position(gui.get_node("pokemon/tab_bg_3"), p)
	gui.set_enabled(gui.get_node("pokemon/tab_bg_2"), false)
	gui.set_enabled(gui.get_node("pokemon/tab_bg_3"), false)

	local page = gui.clone_tree(gui.get_node("pokemon/root"))
	tab_buttons(page)
	table.insert(pokemon_pages, {nodes=page})
	set_ids(page, 1)
	local page = gui.clone_tree(gui.get_node("pokemon/root"))
	tab_buttons(page)
	table.insert(pokemon_pages, {nodes=page})
	set_ids(page, 2)
	gui.set_enabled(page["pokemon/root"], false)

	gui.delete_node(gui.get_node("pokemon/root"))
end

function M.on_input(action_id, action)
	button.on_input(action_id, action)
	moves.on_input(action_id, action)
	features.on_input(action_id, action)
	meters.on_input(action_id, action)
end

local function parse_number(str, current)
	local value
	if string.find(str, "[+-]") ~= nil then
		value = loadstring("return " .. current .. str)() - current
	else
		value = tonumber(str) - current
	end
	return value
end

function M.on_message(message_id, message)
	if message_id == hash("update_exp") then
		local pokemon = storage.get_copy(active_pokemon_id)
		local current_exp = _pokemon.get_exp(pokemon)
		local exp = parse_number(message.str, current_exp)
		_pokemon.set_exp(pokemon, current_exp + exp)
		meters.setup_exp(pokemon_pages[active_page].nodes, pokemon)
	elseif message_id == hash("update_hp") then
		local pokemon = storage.get_copy(active_pokemon_id)
		local current_hp = _pokemon.get_current_hp(pokemon)
		local hp = parse_number(message.str, current_hp)
		meters.add_hp(pokemon, hp)
		meters.setup_hp(pokemon_pages[active_page].nodes, pokemon)
	else
		print("unhandled message: " .. message_id)
	end
end

return M