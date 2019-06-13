local _pokemon = require "pokedex.pokemon"
local storage = require "pokedex.storage"
local gooey = require "gooey.gooey"
local monarch = require "monarch.monarch"
local gui_colors = require "utils.gui_colors"

local M = {}

M.status = {
	BURNING=1,
	FROZEN=2,
	PARALYZED=3,
	POISONED=4,
	ASLEEP=5,
	CONFUSED=6,
}

M.status_names = {
	[M.status.BURNING] = "Burning",
	[M.status.FROZEN] = "Frozen",
	[M.status.PARALYZED] = "Paralyzed",
	[M.status.POISONED] = "Poisoned",
	[M.status.ASLEEP] = "Asleep",
	[M.status.CONFUSED] = "Confused"
}

M.status_colors = {
	[M.status.BURNING] = vmath.vector4(0.96, 0.50, 0.19, 1),
	[M.status.FROZEN] = vmath.vector4(0.6, 0.85, 0.85, 1),
	[M.status.PARALYZED] = vmath.vector4(0.97, 0.816, .19, 1),
	[M.status.POISONED] = vmath.vector4(0.63, 0.21, 0.63, 1),
	[M.status.ASLEEP] = vmath.vector4(0.55, 0.53, 0.55, 1),
	[M.status.CONFUSED] = vmath.vector4(0.47, 0.68, 0.56, 1)
}

M.status_prose = {
	[M.status.BURNING] = "A burned creature's attacks deal half their normal damage. In addition, the creature takes an amount of fire damage equal to its proficiency bonus at the beginning of each of its turns until it faints or is cured of its burns. (Fire types are immune to this status condition)",
	[M.status.FROZEN] = "A frozen creature is incapacitated and restrained. In combat, it can attempt to break free of the ice with a DC 15 STR save at the end of each of its turns. Outside of combat, the frozen status lasts for one hour. (Ice types are immune to this status condition)",
	[M.status.PARALYZED] = "A paralyzed creature has disadvantage on any STR or DEX saving throws, and attacks against it have advantage. After selecting a Move to activate and spend PP on, roll a d4. On a result of 1, it is incapacitated and restrained. The trainer of a fully paralyzed Pokémon still may take an action. (Electric types are immune to this status condition)",
	[M.status.POISONED] = "A poisoned creature has disadvantage on all ability checks and attack rolls, and takes an amount of poison damage equal to its proficiency bonus at the end of each of its turns until it faints or is cured of its poison. If a poisoned creature uses a move that requires a saving throw, the target(s) have advantage on the roll. (Poison and Steel types are immune to this status condition)",
	[M.status.ASLEEP] = "A creature that is asleep is incapacitated and restrained for a maximum of three rounds, failing all STR and DEX saves during that time. A sleeping creature can roll a d20 as a bonus action at the beginning of each of its turns, waking up on a result of 13 or higher.",
	[M.status.CONFUSED] = "A confused creature is affected for 1d4 rounds, as determined by a roll from the attacker at time of confusion. During this time, it loses its ability to take reactions and moves at half speed. After selecting a Move to activate and spend PP on, it must roll a d20. On a result of 9 or lower, the creature hurts itself for an amount of damage equal to its proficiency bonus and may not make an attack, but the trainer of a confused Pokémon still may take an action. On a roll of 20, the creature is no longer confused."
}

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
		[M.status.BURNING] = nodes["pokemon/status_burning"],
		[M.status.FROZEN] = nodes["pokemon/status_frozen"],
		[M.status.PARALYZED] = nodes["pokemon/status_paralyzed"],
		[M.status.POISONED] = nodes["pokemon/status_poisoned"],
		[M.status.ASLEEP] = nodes["pokemon/status_asleep"],
		[M.status.CONFUSED] = nodes["pokemon/status_confused"]
	}
	M.update(current_pokemon_id)
end

function M.update(pokemon_id)
	local effects = storage.get_status_effects(pokemon_id)
	for status, node in pairs(status_nodes) do
		if effects[status] == true then
			gui.set_color(node, M.status_colors[status])
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