local defsave = require "defsave.defsave"
local json = require "defsave.json"
local md5 = require "utils.md5"
local utils = require "utils.utils"
local profiles = require "pokedex.profiles"
local pokedex = require "pokedex.pokedex"
local log = require "utils.log"

local M = {}

local player_pokemon = {}
local counters = {}
local sorting = {}
local initialized = false
local max_active_pokemon = 6

LOCATION_PC = 0
LOCATION_PARTY = 1

local function get_id(pokemon)
	local m = md5.new()
	local p = utils.deep_copy(pokemon)
	p.statuses = nil
	m:update(json.encode(p))
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


local function sort_on_index(a, b)
	return function(a, b) 
		local c = pokedex.get_index_number(a.species.current)
		local d = pokedex.get_index_number(b.species.current)
		return c < d  
	end
end


local function sort_on_caught(a, b)
	return function(a, b) 
		return a.number < b.number  
	end
end


local function sort_on_level(a, b)
	return function(a, b) return a.level.current > b.level.current end
end


local function sort_alphabetical(a, b)
	return function(a, b) return a.species.current < b.species.current end
end


local function sort_on_slot(a, b)
	return function(a, b) return (a.slot or 7) < (b.slot or 7) end
end


function M.is_initialized()
	return initialized
end


function M.get_max_active_pokemon_range()
	return 2,6
end


function M.get_max_active_pokemon()
	return max_active_pokemon
end


function M.set_max_active_pokemon(new_max)
	new_max = M.clamp_max_active_pokemon(new_max)
	if new_max ~= max_active_pokemon then
		max_active_pokemon = new_max
	end
end

function M.clamp_max_active_pokemon(new_max)
	local range_min, range_max = M.get_max_active_pokemon_range()
	return math.max(range_min, math.max(range_min, new_max))
end


function M.is_party_full()
	local counter = 0
	for _, pkmn in pairs(player_pokemon) do
		if pkmn.location == LOCATION_PART then
			counter = counter + 1
		end
	end
	return counter >= M.get_max_active_pokemon()
end


function M.list_of_ids_in_storage()
	local f = M.get_sorting_method()
	local tmp = {}
	for id, pkmn in pairs(player_pokemon) do
		if pkmn.location == LOCATION_PC then
			tmp[id] = pkmn
		end
	end
	return getKeysSortedByValue(tmp, f(a, b))
end


function M.list_of_ids_in_inventory()
	local tmp = {}
	for id, pkmn in pairs(player_pokemon) do
		if pkmn.location == LOCATION_PARTY then
			tmp[id] = pkmn
		end
	end
	return getKeysSortedByValue(tmp, sort_on_slot(a, b))
end


function M.is_inventory_pokemon(id)
	for x, _ in pairs(active) do
		if x == id then
			return true
		end
	end
	return false
end


function M.is_in_storage(id)
	if player_pokemon[id] then
		return true
	end
	return false
end


function M.get_copy(id)
	if player_pokemon[id] then
		return utils.deep_copy(player_pokemon[id])
	else
		local e = string.format("Trying to get '" .. tostring(id) .. "' from storage\n\n%s", debug.traceback())
		gameanalytics.addErrorEvent {
			severity = "Critical",
			message = e
		}
		log.error(e)
		return nil
	end
end


local function get(id)
	return player_pokemon[id]
end


function M.get_pokemon(id)
	return get(id)
end


local function get_party()
	local p = {}
	for _, pokemon in pairs(player_pokemon) do
		if pokemon.location == LOCATION_PARTY then
			table.insert(p, pokemon.species.current)
		end
	end
	return p
end


function M.update_pokemon(pokemon)
	local id = pokemon.id
	if player_pokemon[id] then
		player_pokemon[id] = pokemon
	end
end


function M.get_sorting_method()
	if sorting.method == "alphabetical" then
		return sort_alphabetical
	elseif sorting.method == "level" then
		return sort_on_level
	elseif sorting.method == "index" then
		return sort_on_index
	elseif sorting.method == "caught" then
		return sort_on_caught
	else
		return sort_on_index
	end
end


function M.set_sorting_method(method)
	sorting.method = method
end


function M.release_pokemon(id)
	player_pokemon[id] = nil
	counters.released = next(counters) ~= nil and counters.released + 1 or 1
	profiles.update(profiles.get_active_slot(), counters)
	profiles.set_party(get_party())
end


function M.get_total()
	return counters.caught - counters.released
end


function M.add(pokemon)
	for i=#pokemon.moves, 1, -1 do
		if pokemon.moves[i] == "" or pokemon.moves[i] == "None" then
			table.remove(pokemon.moves, i)
		end
	end
	counters.caught = next(counters) ~= nil and counters.caught + 1 or 1
	pokemon.number = counters.caught

	local id = get_id(pokemon)
	pokemon.id = id
	profiles.update(profiles.get_active_slot(), counters)
	if M.is_party_full() then
		pokemon.location = LOCATION_PC
	else
		pokemon.location = LOCATION_PARTY
		pokemon.slot = #M.list_of_ids_in_inventory() + 1
	end
	player_pokemon[id] = pokemon
	
	profiles.set_party(get_party())
	profiles.save()
end


function M.save()
	if profiles.get_active_slot() then
		local profile = profiles.get_active_file_name()
		defsave.set(profile, "player_pokemon", player_pokemon)
		defsave.set(profile, "counters", counters)
		defsave.set(profile, "sorting", sorting)

		local settings = {
			max_active_pokemon = max_active_pokemon
		}
		defsave.set(profile, "settings", settings)
		defsave.save(profile)
	end
end


function M.load(profile)
	initialized = false
	local file_name = profile.file_name
	if not defsave.is_loaded(file_name) then
		local loaded = defsave.load(file_name)
	end
	player_pokemon = defsave.get(file_name, "player_pokemon")
	counters = defsave.get(file_name, "counters")
	sorting = defsave.get(file_name, "sorting")

	local settings = defsave.get(file_name, "settings")
	max_active_pokemon = M.clamp_max_active_pokemon(settings.max_active_pokemon or 6)
	
	-- Default counters
	if next(counters) == nil then
		counters = {caught=0, released=0, seen=0}
	end
end


function M.init()
	if not initialized then
		local profile = profiles.get_active()
		if profile then
			M.load(profile)
		end
		initialized = true
	end
end


local function assign_slot_numbers()
	log.info("Assigning slot numbers")
	local index = 1
	for id, pokemon in pairs(player_pokemon) do
		if pokemon.location == LOCATION_PART then
			pokemon.slot = index
			index = index + 1
		end
	end
end


function M.swap(pc_pokemon_id, party_pokemon_id)
	local pc_pokemon = player_pokemon[pc_pokemon_id]
	local party_pokemon = player_pokemon[party_pokemon_id]

	-- Set new locations
	pc_pokemon.location = LOCATION_PARTY
	party_pokemon.location = LOCATION_PC

	pc_pokemon.slot = party_pokemon.slot
	party_pokemon.slot = nil

	profiles.set_party(get_party())
end


function M.move_to_storage(id)
	local pokemon = player_pokemon[id]
	pokemon.slot = nil
	pokemon.location = LOCATION_PC
	
	profiles.set_party(get_party())
end


function M.free_space_in_inventory()
	local index = 0
	for _, pokemon in pairs(player_pokemon) do
		if pokemon.location == LOCATION_PC then
			index = index + 1
		end
	end
	return index < M.get_max_active_pokemon(), index + 1
end


function M.move_to_inventory(id)
	local free, slot = M.free_space_in_inventory()
	if free then
		local pokemon = player_pokemon[id]
		pokemon.slot = slot
		pokemon.location = LOCATION_PART
		profiles.set_party(get_party())
	else
		assert(false, "Your party is full")
	end
end


return M