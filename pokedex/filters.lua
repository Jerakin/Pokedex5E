local file = require "utils.file"
local utils = require "utils.utils"
local log = require "utils.log"
local pokedex = require "pokedex.pokedex"

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


local function compare(a,b)
	return a < b
end

local function species_rating()
	for pokemon, data in pairs(_pokedex) do
		local cr = tostring(data.SR)
		if sr[cr] then 
			table.insert(sr[cr], pokemon)
		else 
			sr[cr] = {pokemon}
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
	local dex_indexes = {[1]=151, [2]=251, [3]=386, [4]=493, [5]=649}
	local gen = {[1]={}, [2]={}, [3]={}, [4]={}, [5]={}}
	for pokemon, data in pairs(_pokedex) do
		local index = data.index
		if index <= dex_indexes[1] then
			table.insert(gen[1], pokemon)
		elseif index <= dex_indexes[2] then
			table.insert(gen[2], pokemon)
		elseif index <= dex_indexes[3] then
			table.insert(gen[3], pokemon)
		elseif index <= dex_indexes[4] then
			table.insert(gen[4], pokemon)
		elseif index <= dex_indexes[5] then
			table.insert(gen[5], pokemon)
		end
	end
	return gen
end

function M.init()
	if not initialized then
		_pokedex = pokedex.get_whole_pokedex()
		trainer_classes = file.load_json_from_resource("/assets/datafiles/trainer_classes.json")
		trainer_classes_list = _trainer_classes_list()
		habitats = file.load_json_from_resource("/assets/datafiles/habitat.json")
		pokemon_types = pokemon_types()
		generations = generation_list()
		table.insert(trainer_classes_list, 1, "Optional")
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

	for cr, list in pairs(sr) do 
		cr = tonumber(cr)
		if cr <= max and cr >= min then
			for _, l in pairs(list) do
				table.insert(n, l)
			end
		end
	end
	return n
end

local number_map = {["1/8"]=0.125, ["1/4"]=0.25, ["1/2"]=0.5, ["1"]=1, ["2"]=2, ["3"]=3, ["4"]=4, ["5"]=5, ["6"]=6, ["7"]=7,["8"]=8,
["9"]=9, ["10"]=10, ["11"]=11, ["12"]=12, ["13"]=13, ["14"]=14, ["15"]=15}

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