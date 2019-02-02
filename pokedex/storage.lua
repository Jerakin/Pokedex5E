local defsave = require "defsave.defsave"
local json = require "defsave.json"
local md5 = require "utils.md5"
local utils = require "utils.utils"
local _pokemon = require "pokedex.pokemon"

local M = {}

M.storage = {}
M.active = {}
M.counter = 0


local function get_id(pokemon)
	local m = md5.new()
	m:update(json.encode(pokemon))
	return md5.tohex(m:finish())
end



local function getKeysSortedByValue(tbl, sortFunction)
	local keys = {}
	for key in pairs(tbl) do
		table.insert(keys, key)
	end

	table.sort(keys, function(a, b)
		return sortFunction(tbl[a], tbl[b])
	end)

	return keys
end

function M.list_of_ids_in_storage()
	return getKeysSortedByValue(M.storage, function(a, b) return a.species < b.species end)
end

function M.list_of_ids_in_inventory()
	return getKeysSortedByValue(M.active, function(a, b) return a.species < b.species end)
end

function M.get(id)
	return M.storage[id] and M.storage[id] or M.active[id]
end

function M.add(pokemon)
	for i=#pokemon.moves, 1, -1 do
		if pokemon.moves[i] == "None" then
			table.remove(pokemon.moves, i)
		end
	end
	M.counter = M.counter + 1
	pokemon.number = M.counter
	pokemon.caught_at_level = pokemon.level
	local id = get_id(pokemon)
	local poke = _pokemon.new(pokemon, id)
	M.storage[id] = poke
end

function M.save()
	defsave.set("pokedex5e", "storage", M.storage)
	defsave.set("pokedex5e", "active", M.active)
	defsave.set("pokedex5e", "counter", M.counter)
	defsave.save("pokedex5e")
end

function M.init()
	local loaded = defsave.load("pokedex5e", default_data)
	if loaded then
		M.storage = defsave.get("pokedex5e", "storage")
		M.active = defsave.get("pokedex5e", "active")
		M.counter = defsave.get("pokedex5e", "counter")
	end
end

function M.move_to_storage(id)
	local pokemon = utils.deep_copy(M.active[id])
	M.storage[id] = pokemon
	M.active[id] = nil
end

function M.move_to_inventory(id)
	local index = 0
	for _, _ in pairs(M.active) do
		index = index + 1
	end
	assert(index < 6, "Your party is full")
	local pokemon = utils.deep_copy(M.storage[id])
	M.active[id] = pokemon
	M.storage[id] = nil
end

return M