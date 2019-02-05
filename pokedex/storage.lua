local defsave = require "defsave.defsave"
local json = require "defsave.json"
local md5 = require "utils.md5"
local utils = require "utils.utils"
local _pokemon = require "pokedex.pokemon"
local profiles = require "pokedex.profiles"

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

local function update_pokemon_data(data)
	for id, pokemon in pairs(data) do
		_pokemon.update_pokemon(pokemon)
	end
end

function M.list_of_ids_in_storage()
	return getKeysSortedByValue(M.storage, function(a, b) return a.species < b.species end)
end

function M.list_of_ids_in_inventory()
	return getKeysSortedByValue(M.active, function(a, b) return a.species < b.species end)
end

function M.get_copy(id)
	return utils.deep_copy(M.storage[id] and M.storage[id] or M.active[id])
end

local function get(id)
	return M.storage[id] and M.storage[id] or M.active[id]
end

function M.edit(id, pokemon_data)
	local p = get(id)
	_pokemon.edit(p, pokemon_data)
	M.save()
end

function M.decrease_move_pp(id, move)
	local p = get(id)
	p.moves[move].current_pp = math.max(p.moves[move].current_pp - 1, 0)
	M.save()
	return p.moves[move].current_pp
end

function M.reset_move_pp(id, move)
	local p = get(id)
	p.moves[move].current_pp = p.moves[move].PP
	M.save()
	return p.moves[move].current_pp
end

function M.set_current_hp(id, hp)
	local p = get(id)
	p.current_hp = math.min(math.max(hp, 0), p.HP)
	M.save()
	return p.current_hp
end

function M.add(pokemon)
	for i=#pokemon.moves, 1, -1 do
		if pokemon.moves[i] == "" or pokemon.moves[i] == "None" then
			table.remove(pokemon.moves, i)
		end
	end
	M.counter = M.counter + 1
	pokemon.number = M.counter
	pokemon.caught_at_level = pokemon.level
	local id = get_id(pokemon)
	local poke = _pokemon.new(pokemon, id)

	profiles.update(profiles.get_active(), {caught=M.counter})

	M.storage[id] = poke
	M.save()
end

function M.save()
	if profiles.get_active() then
		local profile = profiles.get_active_file_name()
		defsave.set(profile, "storage", M.storage)
		defsave.set(profile, "active", M.active)
		defsave.set(profile, "counter", M.counter)
		defsave.save(profile)
	end
end

function M.init()
	local profile = profiles.get_active_file_name()
	local loaded = defsave.load(profile)
	if loaded then
		M.storage = defsave.get(profile, "storage")
		M.active = defsave.get(profile, "active")
		M.counter = defsave.get(profile, "counter")
		if not next(M.counter) then
			M.counter = 0
		end
		update_pokemon_data(M.storage)
		update_pokemon_data(M.active)
	end
end

function M.move_to_storage(id)
	local pokemon = utils.deep_copy(M.active[id])
	M.storage[id] = pokemon
	M.active[id] = nil
	M.save()
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
	M.save()
end

return M