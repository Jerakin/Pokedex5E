local file = require "utils.file"
local utils = require "utils.utils"

local M = {}

local pokedex
local abilities
local movedata
local evolvedata
local initialized = false
local function list()
	local ordered = file.load_json_from_resource("/assets/datafiles/pokemon_order.json")
	return ordered.number, #ordered
end

function M.init()
	if not initialized then
		pokedex = file.load_json_from_resource("/assets/datafiles/pokemon.json")
		abilities = file.load_json_from_resource("/assets/datafiles/abilities.json")
		movedata = file.load_json_from_resource("/assets/datafiles/moves.json")
		evolvedata = file.load_json_from_resource("/assets/datafiles/evolve.json")
		M.list, M.total = list()
		initialized = true
	end
end

function M.get_ability_description(ability)
	return abilities[ability].Description
end

function M.get_move_data(move)
	return movedata[move]
end

function M.get_pokemon(pokemon)
	return utils.shallow_copy(pokedex[pokemon])
end

function M.is_pokemon(pokemon)
	return pokedex[pokemon] and true or false
end

function M.minumum_level(pokemon)
	return M.get_pokemon(pokemon)["MIN LVL FD"]
end

function M.can_evolve(pokemon)
	return evolvedata[pokemon] or true and false
end

function M.evolve_level(pokemon)
	return evolvedata[pokemon].level
end

function M.evolve_into(pokemon)
	return evolvedata[pokemon].into
end

function M.evolve_points(pokemon)
	return evolvedata[pokemon].points
end

function M.get_starting_moves(pokemon)
	return M.get_pokemon(pokemon)["Moves"]["Starting Moves"]
end

function M.get_base_attributes(pokemon)
	local attributes = {}
	local pokemon = M.get_pokemon(pokemon)
	attributes.STR = pokemon.STR
	attributes.DEX = pokemon.DEX
	attributes.CON = pokemon.CON
	attributes.INT = pokemon.INT
	attributes.WIS = pokemon.WIS
	attributes.CHA = pokemon.CHA
	attributes.AC = pokemon.AC
	return attributes
end

function M.get_pokemons_moves(pokemon, level)
	level = level or 20
	local moves = M.get_pokemon(pokemon)["Moves"]
	local pick_from = utils.shallow_copy(moves["Starting Moves"])
	for l, move in pairs(moves["Level"]) do
		if tonumber(l) < level then
			for _, m in pairs(move) do
				table.insert(pick_from, m)
			end
		end
	end
	return pick_from
end

return M