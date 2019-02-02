local defsave = require "defsave.defsave"
local json = require "defsave.json"
local md5 = require "utils.md5"
local utils = require "utils.utils"

local M = {}

M.storage = {}
M.active = {}
M.counter = 0

local default_data = {

}

local function get_id(pokemon)
	local m = md5.new()
	m:update(json.encode(pokemon))
	return md5.tohex(m:finish())
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
	local id = get_id(pokemon)
	M.storage[id] = pokemon
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
		pprint(M.counter)
	end
end

function M.move_to_storage(id)
	pprint(id)
	local pokemon = utils.deep_copy(M.active[id])
	pprint(pokemon)
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
	pprint(pokemon)
	pprint(id)
	M.active[id] = pokemon
	M.storage[id] = nil
end

return M