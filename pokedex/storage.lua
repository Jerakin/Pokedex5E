local defsave = require "defsave.defsave"
local json = require "defsave.json"
local md5 = require "utils.md5"
local utils = require "utils.utils"
local _pokemon = require "pokedex.pokemon"
local profiles = require "pokedex.profiles"

local M = {}

local storage = {}
local active = {}
local counters = {}

local initialized = false

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
	return getKeysSortedByValue(storage, function(a, b) return a.species < b.species end)
end

function M.list_of_ids_in_inventory()
	return getKeysSortedByValue(active, function(a, b) return a.species < b.species end)
end

function M.get_copy(id)
	return utils.deep_copy(storage[id] and storage[id] or active[id])
end

local function get(id)
	return storage[id] and storage[id] or active[id]
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

function M.release_pokemon(id)
	storage[id] = nil
	active[id] = nil
	counters.released = next(counters) ~= nil and counters.released + 1 or 1
	profiles.update(profiles.get_active_slot(), counters)
	M.save()
end

function M.add(pokemon)
	for i=#pokemon.moves, 1, -1 do
		if pokemon.moves[i] == "" or pokemon.moves[i] == "None" then
			table.remove(pokemon.moves, i)
		end
	end
	counters.caught = next(counters) ~= nil and counters.caught + 1 or 1
	pokemon.number = counters.caught
	pokemon.caught_at_level = pokemon.level
	local id = get_id(pokemon)
	local poke = _pokemon.new(pokemon, id)

	profiles.update(profiles.get_active_slot(), counters)
	if M.party_is_full() then
		storage[id] = poke
	else
		active[id] = poke
	end
	M.save()
	profiles.save()
end

function M.save()
	if profiles.get_active_slot() then
		local profile = profiles.get_active_file_name()
		defsave.set(profile, "storage", storage)
		defsave.set(profile, "active", active)
		defsave.set(profile, "counters", counters)
		defsave.save(profile)
	end
end

function M.load(profile)
	local file_name = profile.file_name
	local loaded = defsave.load(file_name)
	if loaded then
		storage = defsave.get(file_name, "storage")
		active = defsave.get(file_name, "active")
		counters = defsave.get(file_name, "counters")
		-- Default counters
		if next(counters) == nil then
			counters = {caught=0, released=0, seen=0}
		end
	end
end

function M.init()
	if not initialized then
		M.load(profiles.get_active())
		update_pokemon_data(storage)
		update_pokemon_data(active)
	end
	initialized = true
end

function M.move_to_storage(id)
	local pokemon = utils.deep_copy(active[id])
	storage[id] = pokemon
	active[id] = nil
	M.save()
end

function M.party_is_full()
	local counter = 0
	for _, _ in pairs(active) do
		counter = counter + 1
	end
	return counter >= 6
end

function M.move_to_inventory(id)
	local index = 0
	for _, _ in pairs(active) do
		index = index + 1
	end
	assert(index < 6, "Your party is full")
	local pokemon = utils.deep_copy(storage[id])
	active[id] = pokemon
	storage[id] = nil
	M.save()
end

return M