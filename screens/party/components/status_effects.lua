local _pokemon = require "pokedex.pokemon"
local storage = require "pokedex.storage"
local gooey = require "gooey.gooey"
local monarch = require "monarch.monarch"
local gui_colors = require "utils.gui_colors"
local statuses = require "pokedex.statuses"

local M = {}

local status_nodes
local current_pokemon_id
local active_page
local btn_status 
local active_page 
 
function M.create(nodes, pokemon, page)
	active_page = page or 1
	current_pokemon_id = _pokemon.get_id(pokemon)
	btn_status = nodes["pokemon/btn_status"]
	gui.set_id(btn_status, "btn_status" .. active_page)
	
	status_nodes = {
		[statuses.status.BURNING] = nodes["pokemon/status_burning"],
		[statuses.status.FROZEN] = nodes["pokemon/status_frozen"],
		[statuses.status.PARALYZED] = nodes["pokemon/status_paralyzed"],
		[statuses.status.POISONED] = nodes["pokemon/status_poisoned"],
		[statuses.status.ASLEEP] = nodes["pokemon/status_asleep"],
		[statuses.status.CONFUSED] = nodes["pokemon/status_confused"]
	}
	M.update(current_pokemon_id)
end

function M.update(pokemon_id)
	local effects = storage.get_status_effects(pokemon_id)
	for status, node in pairs(status_nodes) do
		if effects[status] == true then
			gui.set_color(node, statuses.status_colors[status])
		else
			gui.set_color(node, gui_colors.BACKGROUND)
		end
	end
end

function M.on_message(message_id, message)
	if message_id == hash("refresh_status") then
		M.update(current_pokemon_id)
	end
end

function M.on_input(action_id, action)
	gooey.button("btn_status" .. active_page, action_id, action, function() monarch.show("status_effects", nil, {pokemon_id=current_pokemon_id}) end)
end

return M