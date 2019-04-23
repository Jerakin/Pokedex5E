local storage = require "pokedex.storage"
local _pokemon = require "pokedex.pokemon"
local pokedex = require "pokedex.pokedex"
local gui_colors = require "utils.gui_colors"
local button = require "utils.button"
local gooey_buttons = require "utils.gooey_buttons"
local gooey = require "gooey.gooey"
local monarch = require "monarch.monarch"

local log = require "utils.log"
local party_utils = require "screens.party.utils"
local features = require "screens.party.components.features"
local moves = require "screens.party.components.moves"
local information = require "screens.party.components.information"
local meters = require "screens.party.components.meters"
local gesture = require "utils.gesture"

local M = {}

M.last_active_index = nil
M.last_active_id = nil

local active_page = 1

local pokemon_pages = {}

local switching = false

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
	activate_tab(nodes, 1)
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
	M.last_active_id = id
	local pokemon = storage.get_copy(id)
	if pokemon then
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
	else
		local e = "Party can not show pokemon with id: " .. tostring(id)
		gameanalytics.addErrorEvent {
			severity = "Error",
			message = e
		}
		log.error(e)
	end
end

local function reset()
	switching = false
	active_page = 1
	pokemon_pages = {}
end

function M.switch_to_slot(index)
	if switching or M.last_active_index == index then
		return
	end
	switching = true
	M.last_active_index = index
	local pos_index = -1
	local id = storage.list_of_ids_in_inventory()[index]
	if M.last_active_id == id then
		return
	elseif active_page < index then
		pos_index = 1
	end

	M.last_active_id = id
	local old_page = active_page
	active_page = (1-active_page ) + 2
	local active = pokemon_pages[old_page].nodes["pokemon/root"]
	local new = pokemon_pages[active_page].nodes["pokemon/root"]

	M.show(id)
	msg.post(".", "inventory", {index=index})
	gui.set_position(new, vmath.vector3(720*pos_index, -570, 0))
	gui.animate(active, "position.x", (-1*pos_index)*720, gui.EASING_INSINE, 0.3, 0, function()
		switching = false
		gui.set_enabled(active, false)
	end)
	gui.set_enabled(new, true)
	gui.animate(new, "position.x", 0, gui.EASING_INSINE, 0.3, 0, function()
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
	local g = gesture.on_input("Party", action_id, action)
	if g then
		local index = M.last_active_index or 1
		if g.swipe_left then
			M.switch_to_slot(math.min(index + 1), #storage.list_of_ids_in_inventory())
		elseif g.swipe_right then
			M.switch_to_slot(math.max(index - 1, 1))
		end
	end
		
	button.on_input(action_id, action)
	moves.on_input(action_id, action)
	features.on_input(action_id, action)
	meters.on_input(action_id, action)
end

function M.on_message(message_id, message)
	message.active_pokemon_id = M.last_active_id
	meters.on_message(message_id, message)
end


return M