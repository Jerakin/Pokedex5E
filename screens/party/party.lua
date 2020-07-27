local storage = require "pokedex.storage"
local _pokemon = require "pokedex.pokemon"
local pokedex = require "pokedex.pokedex"
local gui_colors = require "utils.gui_colors"
local button = require "utils.button"
local gooey_buttons = require "utils.gooey_buttons"
local gooey = require "gooey.gooey"
local monarch = require "monarch.monarch"
local scrollhandler = require "screens.party.components.scrollhandler"
local log = require "utils.log"
local party_utils = require "screens.party.utils"
local features = require "screens.party.components.features"
local moves = require "screens.party.components.moves"
local information = require "screens.party.components.information"
local meters = require "screens.party.components.meters"
local status_effects = require "screens.party.components.status_effects"
local gesture = require "utils.gesture"
local gui_utils = require "utils.gui"
local screens = require "utils.screens"
local messages = require "utils.messages"

local M = {}

local active_page = 1

local pokemon_pages = {}

local switching = false

local active_index

function M.get_active_index()
	return active_index
end

local function activate_tab(nodes, tab_number)
	scrollhandler.set_active_tab(active_page, tab_number)
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

function M.final()
	features.final()
end

function M.show(index)
	local inventory_ids = storage.list_of_ids_in_inventory()
	if not inventory_ids[index] then
		index = #inventory_ids
		msg.post(".", "inventory", {index=index, instant=true})
	end
	local id = inventory_ids[index]
	
	if storage.is_in_storage(id) then
		local pokemon = storage.get_copy(id)
		local nodes = pokemon_pages[active_page].nodes
		information.create(nodes, pokemon, active_page)
		meters.create(nodes, id)
		moves.create(nodes, pokemon, active_page)
		features.create(nodes, pokemon, active_page)
		status_effects.create(nodes, pokemon, active_page)
		
		button.register(nodes["pokemon/exp_bg"], function()
			monarch.show(screens.INPUT, {}, {sender=msg.url(), message="update_exp", allowed_characters="[%d%+%-]", default_text=storage.get_pokemon_exp(id)})
		end)
	else
		local e = "Party can not show pokemon with id: " .. tostring(id) .. "\n" .. debug.traceback()
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
	if switching or active_index == index then
		return
	end
	switching = true
	
	local pos_index = active_index < index and 1 or -1
	active_index = index
	
	local old_page = active_page
	active_page = active_page == 1 and 2 or 1
	local active = pokemon_pages[old_page].nodes["pokemon/root"]
	local new = pokemon_pages[active_page].nodes["pokemon/root"]

	M.show(active_index)
	scrollhandler.set_active_index(active_page)
	msg.post(".", messages.INVENTORY, {index=active_index})
	gui.set_position(new, vmath.vector3(720*pos_index, 0, 0))
	gui.animate(active, "position.x", (-1*pos_index)*720, gui.EASING_OUTCUBIC, 0.35, 0, function()
		switching = false
		gui.set_enabled(active, false)
	end)
	gui.set_enabled(new, true)
	gui.animate(new, "position.x", 0, gui.EASING_OUTCUBIC, 0.35, 0, function()
		features.clear(old_page)
		moves.clear(old_page)
		scrollhandler.reset()
	end)
	return true
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
	gui.set_id(nodes["pokemon/tab_bg_1"], "tab_bg_1")
	gui.set_id(nodes["pokemon/move/move"], "move")
	gui.set_id(nodes["pokemon/move/interaction_area"], "interaction_area")
end

function M.create(index)
	reset()
	active_index = index
	local p = gui.get_position(gui.get_node("pokemon/tab_bg_1"))
	gui.set_position(gui.get_node("pokemon/tab_bg_2"), p)
	gui.set_position(gui.get_node("pokemon/tab_bg_3"), p)
	gui.set_enabled(gui.get_node("pokemon/tab_bg_2"), false)
	gui.set_enabled(gui.get_node("pokemon/tab_bg_3"), false)

	local page = gui.clone_tree(gui.get_node("pokemon/root"))
	tab_buttons(page)
	table.insert(pokemon_pages, {nodes=page})
	set_ids(page, 1)
	gui_utils.scale_fit_node_with_stretch(page["pokemon/tab_bg_1"])
	gui_utils.scale_fit_node_with_stretch(page["pokemon/tab_bg_3"])
	gui.set_id(page["pokemon/btn_rest"], "btn_rest_1")
	scrollhandler.set_root_node(1, page["pokemon/root"])
	
	local page = gui.clone_tree(gui.get_node("pokemon/root"))
	tab_buttons(page)
	table.insert(pokemon_pages, {nodes=page})
	set_ids(page, 2)
	gui.set_enabled(page["pokemon/root"], false)
	gui_utils.scale_fit_node_with_stretch(page["pokemon/tab_bg_1"])
	gui_utils.scale_fit_node_with_stretch(page["pokemon/tab_bg_3"])
	gui.set_id(page["pokemon/btn_rest"], "btn_rest_2")
	scrollhandler.set_root_node(2, page["pokemon/root"])

	scrollhandler.set_size_of_scroll_area(gui.get_size(gui.get_node("pokemon/__scroll_end")).y)
	scrollhandler.reset()
	scrollhandler.set_active_index(1)
	gui.delete_node(gui.get_node("pokemon/root"))
end

function M.on_input(action_id, action, consume)
	local g = gesture.on_input("Party", action_id, action)
	if g then
		if g.swipe_left then
			return M.switch_to_slot(math.min(active_index + 1, #storage.list_of_ids_in_inventory()))
		elseif g.swipe_right then
			return M.switch_to_slot(math.max(active_index - 1, 1))
		end
	end
	if not scrollhandler.on_input(action_id, action) then
		information.on_input(action_id, action)
		button.on_input(action_id, action)
		if not consume then
			moves.on_input(action_id, action)
		end
		meters.on_input(action_id, action)
		status_effects.on_input(action_id, action)
	end
end

function M.on_message(message_id, message)
	information.on_message(message_id, message, sender)
	message.active_index = active_index
	meters.on_message(message_id, message)
	status_effects.on_message(message_id, message)
	moves.on_message(message_id, message, active_page)
	
end


return M