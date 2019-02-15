local file = require "utils.file"
local utils = require "utils.utils"


local M = {}

local pokedex
local abilities
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
		evolvedata = file.load_json_from_resource("/assets/datafiles/evolve.json")
		leveldata = file.load_json_from_resource("/assets/datafiles/leveling.json")
		M.list, M.total = list()
		initialized = true
	end
end

function M.get_sprite(pokemon)
	local pokemon_index = M.get_index_number(pokemon)
	local texture = "pokemon" .. math.floor(pokemon_index/256)
	local pokemon_sprite = pokemon_index .. pokemon
	if pokemon_index == 32 or pokemon_index == 29 then
		pokemon_sprite = pokemon_sprite:sub(1, -5)
	end

	return pokemon_sprite, texture
end

function M.level_data(level)
	return leveldata[tostring(level)]
end

function M.get_senses(pokemon)
	return M.get_pokemon(pokemon).Senses or {}
end

function M.get_index_number(pokemon)
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

function M.get_walking_speed(pokemon)
	return M.get_pokemon(pokemon).WSp or 0
end

function M.get_swimming_speed(pokemon)
	return M.get_pokemon(pokemon).Ssp or 0
end

function M.get_flying_speed(pokemon)
	return M.get_pokemon(pokemon).Fsp or 0
end

function M.get_climbing_speed(pokemon)
	return M.get_pokemon(pokemon)["Climbing Speed"] or 0
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
		if level >= tonumber(l) then
			for _, m in pairs(move) do
				table.insert(pick_from, m)
			end
		end
	end
	return pick_from
end

return M