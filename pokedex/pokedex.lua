local file = require "utils.file"
local utils = require "utils.utils"

local M = {}

local pokedex
local abilities
local movedata
local evolvedata
local leveldata

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
		leveldata = file.load_json_from_resource("/assets/datafiles/leveling.json")
		M.list, M.total = list()
		initialized = true
	end
end

function M.level_data(level)
	return leveldata[tostring(level)]
end

function M.get_get_index_number(pokemon)
	return M.get_pokemon(pokemon).index
end

function M.get_pokemon_vulnerabilities(pokemon)
	return M.get_pokemon(pokemon).Vul
end

function M.get_pokemon_immunities(pokemon)
	return M.get_pokemon(pokemon).Imm
end

function M.get_pokemon_resistances(pokemon)
	return M.get_pokemon(pokemon).Res
	
end

function M.get_pokemon_type(pokemon)
	return M.get_pokemon(pokemon).Type
end

function M.get_ability_description(ability)
	return abilities[ability].Description
end

function M.get_pokemon_abilities(pokemon)
	return M.get_pokemon(pokemon).Abilities
end

function M.get_pokemon_skills(pokemon)
	return M.get_pokemon(pokemon).Skill
end

function M.get_base_hp(pokemon)
	return M.get_pokemon(pokemon).HP
end

function M.get_move_data(move)
	return movedata[move]
end

function M.get_move_pp(move)
	return movedata[move] and movedata[move].PP
end

function M.get_pokemon_AC(pokemon)
	return M.get_pokemon(pokemon).AC
end
function M.get_pokemon(pokemon)
	return utils.shallow_copy(pokedex[pokemon])
end

function M.get_minimum_wild_level(pokemon)
	return M.get_pokemon(pokemon)["MIN LVL FD"]
end

function M.get_evolution_possible(pokemon)
	return evolvedata[pokemon] or true and false
end

function M.get_evolution_level(pokemon)
	return evolvedata[pokemon].level
end

function M.get_evolutions(pokemon)
	return evolvedata[pokemon].into
end

function M.evolve_points(pokemon)
	return evolvedata[pokemon].points
end

function M.get_starting_moves(pokemon)
	return M.get_pokemon(pokemon)["Moves"]["Starting Moves"]
end

function M.get_base_attributes(pokemon)
	return M.get_pokemon(pokemon).attributes
end

function M.get_saving_throw_proficiencies(pokemon)
	return M.get_pokemon(pokemon).saving_throws
end

function M.get_pokemon_hit_dice(pokemon)
	return M.get_pokemon(pokemon)["Hit Dice"]
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