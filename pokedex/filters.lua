local file = require "utils.file"
local utils = require "utils.utils"
local log = require "utils.log"
local fakemon = require "fakemon.fakemon"
local pokedex = require "pokedex.pokedex"
local dex_data = require "pokedex.dex_data"
local constants = require "utils.constants"

local M = {}

local trainer_classes
local trainer_classes_list
local habitats
local initialized
local pokemon_types
local sr = {}
local minimum_level = {}

local generations

local _pokedex

local SR_GROUPING = {}

local function compare(a,b)
	return a < b
end

local function species_rating()
	for pokemon, data in pairs(_pokedex) do
		local cr = tostring(data.SR)
		if SR_GROUPING[cr] then 
			table.insert(SR_GROUPING[cr], pokemon)
		else 
			SR_GROUPING[cr] = {pokemon}
		end
	end
end

local function minimum_found_level()
	for pokemon, data in pairs(_pokedex) do
		local min_lvl = tostring(data["MIN LVL FD"])
		if minimum_level[min_lvl] then 
			table.insert(minimum_level[min_lvl], pokemon)
		else 
			minimum_level[min_lvl] = {pokemon}
		end
	end
end

local function pokemon_types()
	local t = {}
	for pokemon, data in pairs(_pokedex) do
		for _, type in pairs(data.Type) do
			if not t[type] then
				t[type] = {}
			end
			table.insert(t[type], pokemon)
		end
	end
	table.sort(t, compare)
	return t
end

local function _trainer_classes_list()
	local t = {}
	for trainer, _ in pairs(trainer_classes) do
		table.insert(t, trainer)
	end
	table.sort(t, compare)
	return t
end

local function generation_list()
	local dex_indexes = dex_data.max_index
	local output = {}
	for pokemon, data in pairs(_pokedex) do
		local index = data.index
		for _, gen in pairs(dex_data.order) do
			local max = dex_indexes[gen]
			if index <= max then
				if output[gen] == nil then
					output[gen] = {}
				end
				table.insert(output[gen], pokemon)
				break
			end
		end
	end
	return output
end

function M.init()
	if not initialized then
		_pokedex =file.load_json_from_resource("/assets/datafiles/filter_data.json")
		trainer_classes = file.load_json_from_resource("/assets/datafiles/trainer_classes.json")
		trainer_classes_list = _trainer_classes_list()
		habitats = file.load_json_from_resource("/assets/datafiles/habitat.json")
		pokemon_types = pokemon_types()
		generations = generation_list()
		table.insert(trainer_classes_list, 1, "Optional")
		if fakemon.pokemon then
			for name, data in pairs(fakemon.pokemon) do
				_pokedex[name].index = data.index
				_pokedex[name].SR = data.SR
				_pokedex[name].Type = data.Type
				_pokedex[name]["MIN LVL FD"] = data["MIN LVL FD"]
			end
		end
		if fakemon.trainer_classes then
			for name, data in pairs(fakemon.trainer_classes) do
				trainer_classes[name] = data
			end
		end
		if fakemon.trainer_classes_list then
			for name, data in pairs(fakemon.trainer_classes_list) do
				trainer_classes_list[name] = data
			end
		end
		if fakemon.habitats then
			for name, data in pairs(fakemon.habitats) do
				habitats[name] = data
			end
		end
		if fakemon.pokemon_types then
			for name, data in pairs(fakemon.pokemon_types) do
				pokemon_types[name] = data
			end
		end
		

		habitats.Optional = pokedex.list
		pokemon_types.Optional = pokedex.list
		trainer_classes.Optional = pokedex.list
		species_rating()
		minimum_found_level()
		initialized = true
	end
end

local function filter(t1, t2)
	local out = {}
	local cache = {}
	if not t1 or not t2 then
		return out
	end
	for _, v in pairs(t1) do
		for _, b  in pairs(t2) do
			if v == b and not cache[b] then
				cache[b] = true
				table.insert(out, b)
			end
		end
	end

	return out
end

local function SR_list(min, max)
	local n = {}

	for cr, list in pairs(SR_GROUPING) do 
		cr = tonumber(cr)
		if cr <= max and cr >= min then
			for _, l in pairs(list) do
				table.insert(n, l)
			end
		end
	end
	return n
end


local function minimum_level_list(lvl)
	local n = {}
	if lvl == 0 then
		return habitats.Optional
	end
	for m_lvl, list in pairs(minimum_level) do
		m_lvl = tonumber(m_lvl)
		if m_lvl <= lvl then
			for _, l in pairs(list) do
				table.insert(n, l)
			end
		end
	end
	return n
end

local function get_generations(min, max)
	local n = {}

	for gen, list in pairs(generations) do 
		if gen <= max and gen >= min then
			for _, p in pairs(list) do
				table.insert(n, p)
			end
		end
	end
	return n
end

function M.get_list(trainer_class, habitat, sr_min, sr_max, min_level, type, min_generation, max_generation)
	local class_habitat = filter(trainer_classes[trainer_class], habitats[habitat]) 
	local class_habitat_sr = filter(class_habitat, SR_list(sr_min, sr_max))
	local class_habitat_sr_lvl = filter(class_habitat_sr, minimum_level_list(min_level))
	local class_habitat_sr_lvl_type = filter(class_habitat_sr_lvl, pokemon_types[type])
	local class_habitat_sr_lvl_type_generation = filter(class_habitat_sr_lvl_type, get_generations(min_generation, max_generation))
	return class_habitat_sr_lvl_type_generation
end

function M.habitat_list()
	local l = {}
	for t,_ in pairs(habitats) do
		if t ~= "Optional" then
			table.insert(l, t)
		end
	end
	
	table.sort(l, compare)
	table.insert(l, 1, "Optional")
	return l
end

function M.trainer_class_list()
	return trainer_classes_list
end


function M.type_list()
	local l = {}
	for t,_ in pairs(pokemon_types) do
		if t ~= "Optional" then
			table.insert(l, t)
		end
	end
	table.sort(l, compare)
	table.insert(l, 1, "Optional")
	return l
end


return M