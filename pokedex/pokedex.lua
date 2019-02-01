local file = require "utils.file"

local M = {}


local function list()
	local ordered = file.load_json_from_resource("/assets/datafiles/pokemon_order.json")
	return ordered.number, #ordered
end

function M.init()
	M.pokedex = file.load_json_from_resource("/assets/datafiles/pokemon.json")
	M.list, M.total = list()
end

local function get_pokemon(pokemon)
	return M.pokedex[pokemon]
end

function M.is_pokemon(pokemon)
	return get_pokemon(pokemon) and true or false
end

function M.minumum_level(pokemon)
	return get_pokemon(pokemon)["MIN LVL FD"]
end

function M.get_pokemons_moves(pokemon, level)
	level = level or 20
	local moves = get_pokemon(pokemon)["Moves"]
	local pick_from = moves["Starting Moves"]
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