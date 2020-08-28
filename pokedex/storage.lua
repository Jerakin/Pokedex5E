local defsave = require "defsave.defsave"
local json = require "defsave.json"
local md5 = require "utils.md5"
local utils = require "utils.utils"
local pokedex = require "pokedex.pokedex"
local log = require "utils.log"
local broadcast = require "utils.broadcast"
local messages = require "utils.messages"

local M = {}



-- All of these tables are saved out to a file, so be sure they are raw data only (no functions, userdata, that sort of thing)
local storage_data = {} -- contains all the below tables
local player_pokemon = {}
local pokemon_by_location = {}

local counters = {}
local sorting = {}
local storage_settings = {}

local initialized = false


local LOCATION_PC = 0
local LOCATION_PARTY = 1

local LATEST_VERSION = 2

local DEFAULT_STORAGE_DATA = {player_pokemon={}, counters={caught=0, released=0, seen=0}, sorting={}, settings={max_party_pokemon=3}, version=LATEST_VERSION}

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
	return function(a, b) return a.slot < b.slot end
end

local function clamp_max_party_pokemon(new_max)
	local range_min, range_max = M.get_max_party_pokemon_range()
	return math.max(range_min, math.max(range_min, new_max))
end

local function get_party()
	local p = {}
	for id, _ in pairs(pokemon_by_location.party) do
		table.insert(p, player_pokemon[id].species.current)
	end
	return p
end

function M.is_initialized()
	return initialized
end


function M.get_max_party_pokemon_range()
	return 2,6
end


function M.get_max_party_pokemon()
	return storage_settings.max_party_pokemon
end


function M.set_max_party_pokemon(new_max)
	new_max = clamp_max_party_pokemon(new_max)
	if new_max ~= storage_settings.max_party_pokemon then
		storage_settings.max_party_pokemon = new_max
	end
end


function M.is_party_full()
	local free_space, _ = M.free_space_in_party()
	return not free_space
end


function M.list_of_ids_in_pc()
	local f = M.get_sorting_method()
	local tmp = {}
	for id, _ in pairs(pokemon_by_location.pc) do
		tmp[id] = player_pokemon[id]
	end
	return getKeysSortedByValue(tmp, f(a, b))
end


function M.list_of_ids_in_party()
	local tmp = {}
	for id, _ in pairs(pokemon_by_location.party) do
		tmp[id] = player_pokemon[id]
	end
	return getKeysSortedByValue(tmp, sort_on_slot(a, b))
end


function M.is_party_pokemon(id)
	return player_pokemon[id].location == LOCATION_PARTY
end


function M.is_in_storage(id)
	return player_pokemon[id] ~= nil
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
	if pokemon_by_location.party[id] then
		pokemon_by_location.party[id] = nil
		broadcast.send(messages.PARTY_UPDATED, {party=get_party()})
	else
		pokemon_by_location.pc[id] = nil
		broadcast.send(messages.PC_UPDATED)
	end
	counters.released = next(counters) ~= nil and counters.released + 1 or 1
	broadcast.send(messages.COUNTERS_UPDATED, {counters=counters})
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

	player_pokemon[id] = pokemon
	if M.is_party_full() then
		pokemon.location = LOCATION_PC
		pokemon_by_location.pc[id] = true
		broadcast.send(messages.PC_UPDATED)
	else
		pokemon.location = LOCATION_PARTY
		pokemon.slot = #M.list_of_ids_in_party() + 1
		pokemon_by_location.party[id] = true
		broadcast.send(messages.PARTY_UPDATED, {party=get_party()})
	end

	broadcast.send(messages.SAVE_POKEMON)
	broadcast.send(messages.COUNTERS_UPDATED, {counters=counters})
end

function M.get_data()
	return storage_data
end

local function upgrade_data(file_name, storage_data)
	local version = storage_data and storage_data.version or 1

	local needs_upgrade = version ~= LATEST_VERSION
	
	if needs_upgrade then
		for i=version,LATEST_VERSION-1 do
			if false then

			-- NOTE: If a new data upgrade is needed then update the LATEST_VERSION at the top of the file add a new block here like so:

			--elseif i == ??? then
				
			elseif i == 1 then
				
				-- Old data was storage in different sections of file, need to pull out that data, upgrade it, and clear out the old stuff
				assert(next(storage_data) == nil, "Assumed that version 1 did not have storage data saved")

				-- Counters needs initialization if it didn't exist before
				storage_data.counters = defsave.get(file_name, "counters")
				if next(storage_data.counters) == nil then
					storage_data.counters = {caught=0, released=0, seen=0}
				end
				
				storage_data.sorting = defsave.get(file_name, "sorting")

				-- Settings were stored in a separate section because MagRoader didn't understand the system very well at the time
				local settings = defsave.get(file_name, "settings")
				storage_data.settings = 
				{
					max_party_pokemon = settings.max_active_pokemon or 6
				}

				-- Storage and Active == PC and Party
				local pc_pokemon = defsave.get(file_name, "storage") or {}
				local party_pokemon = defsave.get(file_name, "active") or {}

				storage_data.player_pokemon = {}
				for id,data in pairs(pc_pokemon) do
					data.location = LOCATION_PC
					storage_data.player_pokemon[id] = data
				end
				for id,data in pairs(party_pokemon) do
					data.location = LOCATION_PARTY
					storage_data.player_pokemon[id] = data
				end

				-- Remove old style of data
				defsave.set(file_name, "storage", nil)
				defsave.set(file_name, "active", nil)
				defsave.set(file_name, "counters", nil)
				defsave.set(file_name, "settings", nil)
			else
				assert(false, "Unknown storage data version " .. storage_data.version)
			end
		end

		storage_data.version = LATEST_VERSION
	end

	return storage_data, needs_upgrade
end

function M.load(data)
	data = data or utils.deep_copy(DEFUALT_STORAGE_DATA)
	local loaded_data, needs_save = upgrade_data(file_name, data)
	storage_data = loaded_data

	-- Extract everything we need from saved data
	player_pokemon = storage_data.player_pokemon
	counters = storage_data.counters
	sorting = storage_data.sorting
	storage_settings = storage_data.settings


	-- create the pokemon id lists
	pokemon_by_location.pc = {}
	pokemon_by_location.party = {}
	for _id, pkmn in pairs(player_pokemon) do
		if pkmn.location == LOCATION_PC then
			pokemon_by_location.pc[_id] = true
		else
			pokemon_by_location.party[_id] = true
		end
	end
	return needs_save -- TODO: whoever kicks off the load should save after this, as it means there was a data upgrade
end


function M.swap(pc_pokemon_id, party_pokemon_id)
	local pc_pokemon = player_pokemon[pc_pokemon_id]
	local party_pokemon = player_pokemon[party_pokemon_id]
	local id

	-- Update location id
	pokemon_by_location.party[party_pokemon] = nil
	pokemon_by_location.pc[party_pokemon] = true

	pokemon_by_location.party[pc_pokemon_id] = true
	pokemon_by_location.pc[pc_pokemon_id] = nil
	
	-- Set new locations
	pc_pokemon.location = LOCATION_PARTY
	party_pokemon.location = LOCATION_PC

	pc_pokemon.slot = party_pokemon.slot
	party_pokemon.slot = nil

	broadcast.send(messages.PARTY_UPDATED, {party=get_party()})
	broadcast.send(messages.PC_UPDATED)
end


function M.move_to_pc(pokemon_id)
	local pokemon = player_pokemon[pokemon_id]
	pokemon.slot = nil
	pokemon.location = LOCATION_PC

	-- Update location id
	pokemon_by_location.party[pokemon_id] = nil
	pokemon_by_location.pc[pokemon_id] = true

	broadcast.send(messages.PARTY_UPDATED, {party=get_party()})
	broadcast.send(messages.PC_UPDATED)
end


function M.free_space_in_party()
	local index = 0
	for _,_ in pairs(pokemon_by_location.party) do
		index = index + 1
	end
	return index < M.get_max_party_pokemon(), index + 1
end


function M.move_to_party(pokemon_id)
	local free, slot = M.free_space_in_party()
	if free then
		local pokemon = player_pokemon[pokemon_id]
		pokemon.slot = slot
		pokemon.location = LOCATION_PARTY

		-- Update location id
		pokemon_by_location.party[pokemon_id] = true
		pokemon_by_location.pc[pokemon_id] = nil

		broadcast.send(messages.PARTY_UPDATED, {party=get_party()})
		broadcast.send(messages.PC_UPDATED)
	else
		assert(false, "Your party is full")
	end
end


return M