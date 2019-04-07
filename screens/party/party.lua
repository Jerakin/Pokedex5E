local storage = require "pokedex.storage"
local _pokemon = require "pokedex.pokemon"
local pokedex = require "pokedex.pokedex"
local gui_colors = require "utils.gui_colors"
local button = require "utils.button"
local gooey_buttons = require "utils.gooey_buttons"
local gooey = require "gooey.gooey"
local monarch = require "monarch.monarch"

local party_utils = require "screens.party.utils"
local features = require "screens.party.features"
local moves = require "screens.party.moves"
local information = require "screens.party.information"
local meters = require "screens.party.meters"

local M = {}

M.current_pokemon = ""

M.last_active = 1

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
	active_pokemon_id = id
	local pokemon = storage.get_copy(id)
	local nodes = pokemon_pages[active_page].nodes
	information.create(nodes, pokemon)
	meters.create(nodes, pokemon)
	moves.create(nodes, pokemon)
	features.setup_features(nodes, pokemon)
	
	button.register(nodes["pokemon/exp_bg"], function()
		monarch.show("input", {}, {sender=msg.url(), message="update_exp", allowed_characters="[%d%+%-]", default_text=storage.get_pokemon_exp(id)})
	end)

	button.register(nodes["pokemon/hp_bar_bg"], function()
		monarch.show("input", {}, {sender=msg.url(), message="update_hp", allowed_characters="[%d%+%-]", default_text=storage.get_pokemon_current_hp(id)})
	end)
end

local function reset()
	pokemon_pages = {}
	active_pokemon_id = nil
end

function M.switch_to_slot(index)
	local id = storage.list_of_ids_in_inventory()[index]
	local new_page = (1-active_page) + 2
	local active = pokemon_pages[active_page].nodes["pokemon/root"]
	local new = pokemon_pages[new_page].nodes["pokemon/root"]
	active_page = new_page
	M.show(id)

	gui.animate(active, "position.x", 720, gui.EASING_INSINE, 0.5, 0, function()
		gui.set_enabled(active, false)
	end)
	gui.animate(new, "position.x", 0, gui.EASING_INSINE, 0.5, 0, function()
		gui.set_enabled(new, true)
	end)
end

function M.create()
	reset()
	local p = gui.get_position(gui.get_node("pokemon/tab_bg_1"))
	gui.set_position(gui.get_node("pokemon/tab_bg_2"), p)
	gui.set_position(gui.get_node("pokemon/tab_bg_3"), p)
	gui.set_enabled(gui.get_node("pokemon/tab_bg_2"), false)
	gui.set_enabled(gui.get_node("pokemon/tab_bg_3"), false)

	for i=1, 2 do
		local page = gui.clone_tree(gui.get_node("pokemon/root"))
		tab_buttons(page)
		table.insert(pokemon_pages, {nodes=page})
	end
	gui.set_position(pokemon_pages[2].nodes["pokemon/root"], vmath.vector3(0, 720, 0))
	gui.set_enabled(pokemon_pages[2].nodes["pokemon/root"], false)
	
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