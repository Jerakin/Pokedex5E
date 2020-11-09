local profiles = require "pokedex.profiles"
local pokedex = require "pokedex.pokedex"
local dex_data = require "pokedex.dex_data"
local storage = require "pokedex.storage"
local utils = require "utils.utils"
local log = require "utils.log"
local _pokemon = require "pokedex.pokemon"

local M = {}

local dex = {}

local initialized = false

M.states = {SEEN=1, CAUGHT=2, UNENCOUNTERED=3}

local dex_stats = {
	[dex_data.regions.OTHER]={[1]=0, [2]=0}, 
	[dex_data.regions.KANTO]={[1]=0, [2]=0}, 
	[dex_data.regions.JOHTO]={[1]=0, [2]=0}, 
	[dex_data.regions.HOENN]={[1]=0, [2]=0}, 
	[dex_data.regions.SINNOH]={[1]=0, [2]=0}, 
	[dex_data.regions.UNOVA]={[1]=0, [2]=0},
	[dex_data.regions.KALOS]={[1]=0, [2]=0}
}


local function region_from_index(index)
	local is_region = 0
	for _, region in ipairs(dex_data.order) do
		number = dex_data.max_index[region]
		is_region = region
		if index <= number then
			break
		end
	end
	return is_region
end

function M.update_region_stats()
	dex_stats = {
		[dex_data.regions.OTHER]={[1]=0, [2]=0}, 
		[dex_data.regions.KANTO]={[1]=0, [2]=0}, 
		[dex_data.regions.JOHTO]={[1]=0, [2]=0}, 
		[dex_data.regions.HOENN]={[1]=0, [2]=0}, 
		[dex_data.regions.SINNOH]={[1]=0, [2]=0}, 
		[dex_data.regions.UNOVA]={[1]=0, [2]=0},
		[dex_data.regions.KALOS]={[1]=0, [2]=0},
		[dex_data.regions.ALOLA]={[1]=0, [2]=0}
		
	}

	for index, state in pairs(dex) do
		local region = region_from_index(index)
		dex_stats[region][state] = dex_stats[region][state] + 1
		
		if state == M.states.CAUGHT then
			dex_stats[region][M.states.SEEN] = dex_stats[region][M.states.SEEN] + 1
		end
	end
end

function M.get_region_seen(region)
	return dex_stats[region][M.states.SEEN]
end

function M.get_region_caught(region)
	return dex_stats[region][M.states.CAUGHT]
end


function M.set(species, state)
	local index = pokedex.get_index_number(species)

	local old_state = M.get(species)
	if state == old_state then
		return
	end

	if state == M.states.UNENCOUNTERED then
		state = nil
	end
	dex[index] = state
	M.update_region_stats()
end

function M.get(species)
	local index = pokedex.get_index_number(species)
	return dex[index] or M.states.UNENCOUNTERED
end

local function get_initial_from_storage()
	local _dex = {}
	for _, id in pairs(storage.list_of_ids_in_pc()) do
		local pokemon = storage.get_copy(id)
		local index = pokedex.get_index_number(_pokemon.get_current_species(pokemon))
		_dex[index] = M.states.CAUGHT
	end
	for _, id in pairs(storage.list_of_ids_in_party()) do
		local pokemon = storage.get_pokemon(id)
		local index = pokedex.get_index_number(_pokemon.get_current_species(pokemon))
		_dex[index] = M.states.CAUGHT
	end
	return _dex
end

local function is_valid()
	for index, state in pairs(dex) do
		if tonumber(index) == nil then
			return false
		end
	end
	return true
end

local function convert()
	local e = string.format("Converting the Pokedex")
	gameanalytics.addErrorEvent {
		severity = "Info",
		message = e
	}
	log.info(e)
	
	local _dex = {}
	for species, state in pairs(dex) do
		local index = pokedex.get_index_number(species)
		if index ~= nil then
			_dex[index] = state
		end
	end
	return _dex
end

function M.load(profile)
	dex = profile.pokedex
	if dex == nil then
		dex = get_initial_from_storage()
	elseif not is_valid() then
		dex = convert()
	end
	
	M.update_region_stats()
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

function M.save()
	profiles.update(profiles.get_active_slot(), {pokedex=dex})
end

return M