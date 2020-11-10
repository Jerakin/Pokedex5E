local _pokemon = require "pokedex.pokemon"
local storage = require "pokedex.storage"
local gooey = require "gooey.gooey"
local monarch = require "monarch.monarch"
local gui_colors = require "utils.gui_colors"
local statuses = require "pokedex.statuses"
local screens = require "utils.screens"
local messages = require "utils.messages"

local M = {}

local status_nodes
local current_pokemon_id
local active_page
local btn_status 
local active_page 
local active_nodes
local no_status_txt
 
function M.create(nodes, pokemon, page)
	active_nodes = nodes
	active_page = page or 1
	current_pokemon_id = _pokemon.get_id(pokemon)
	btn_status = nodes["pokemon/btn_status_hitbox"]
	no_status_txt = nodes["pokemon/txt_no_status"]
	gui.set_id(btn_status, "btn_status_hitbox" .. active_page)
	
	status_nodes = {
		[statuses.status.BURNING] = nodes["pokemon/status_burning"],
		[statuses.status.FROZEN] = nodes["pokemon/status_frozen"],
		[statuses.status.PARALYZED] = nodes["pokemon/status_paralyzed"],
		[statuses.status.POISONED] = nodes["pokemon/status_poisoned"],
		[statuses.status.ASLEEP] = nodes["pokemon/status_asleep"],
		[statuses.status.CONFUSED] = nodes["pokemon/status_confused"]
	}
	M.update(nodes, current_pokemon_id)
end

function M.update(nodes, pokemon_id)
	local pkmn = storage.get_pokemon(pokemon_id)
	local effects = _pokemon.get_status_effects(pkmn)
	gui.set_enabled(no_status_txt, true)
	
	for status, node in pairs(status_nodes) do
		gui.set_enabled(node, effects[status])
		if effects[status] == true then
			gui.set_enabled(no_status_txt, false)
			gui.set_color(node, statuses.status_colors[status])
		else
			gui.set_color(node, gui_colors.BACKGROUND)
		end
	end
end

function M.on_message(message_id, message)
	if message_id == messages.REFRESH_STATUS then
		M.update(active_nodes, current_pokemon_id)
	end
end

function M.on_input(action_id, action)
	if active_page then
		gooey.button("btn_status_hitbox" .. active_page, action_id, action, function() monarch.show(screens.STATUS_EFFECTS, nil, {pokemon_id=current_pokemon_id}) end)
	end
end

return M
