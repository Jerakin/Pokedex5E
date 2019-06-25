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

function M.init()
	if not initialized then
		_pokedex = file.load_json_from_resource("/assets/datafiles/pokemon.json")
		trainer_classes = file.load_json_from_resource("/assets/datafiles/trainer_classes.json")
		trainer_classes_list = file.load_json_from_resource("/assets/datafiles/trainer_classes_list.json")
		habitats = file.load_json_from_resource("/assets/datafiles/habitat.json")
		pokemon_types = file.load_json_from_resource("/assets/datafiles/pokemon_types.json")
		

		trainer_classes_list.Classes[#trainer_classes_list.Classes + 1] = "Optional"
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

function M.get_list(trainer_class, habitat, sr_min, sr_max, min_level, type)
	local class_habitat = filter(trainer_classes[trainer_class], habitats[habitat]) 
	local class_habitat_sr = filter(class_habitat, SR_list(sr_min, sr_max))
	local class_habitat_sr_lvl = filter(class_habitat_sr, minimum_level_list(min_level))
	local class_habitat_sr_lvl_type = filter(class_habitat_sr_lvl, pokemon_types[type])
	return class_habitat_sr_lvl_type
end

function M.habitat_list()
	local l = {}
	for t,_ in pairs(habitats) do
		table.insert(l, t)
	end
	table.sort(l, compare)
	return l
end

function M.trainer_class_list()
	table.sort(trainer_classes_list.Classes, compare)
	return trainer_classes_list.Classes
end


function M.type_list()
	local l = {}
	
	for t,_ in pairs(pokemon_types) do
		table.insert(l, t)
	end
	table.sort(l, compare)
	return l
end


return M