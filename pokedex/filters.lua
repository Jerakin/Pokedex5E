local file = require "utils.file"
local utils = require "utils.utils"
local log = require "utils.log"

local M = {}

local trainer_classes
local trainer_classes_list
local habitats
local initialized
local sr = {}


local function species_rating()
	local pokedex = file.load_json_from_resource("/assets/datafiles/pokemon.json")
	for pokemon, data in pairs(pokedex) do
		local cr = tostring(data.CR)
		if sr[cr] then 
			table.insert(sr[cr], pokemon)
		else 
			sr[cr] = {pokemon}
		end
	end
end


function M.init()
	if not initialized then
		trainer_classes = file.load_json_from_resource("/assets/datafiles/trainer_classes.json")
		trainer_classes_list = file.load_json_from_resource("/assets/datafiles/trainer_classes_list.json")
		habitats = file.load_json_from_resource("/assets/datafiles/habitat.json")
		local ordered = file.load_json_from_resource("/assets/datafiles/pokemon_order.json")
		trainer_classes_list.Classes[#trainer_classes_list.Classes + 1] = "No Trainer"
		habitats.All = ordered.number
		trainer_classes["No Trainer"] = ordered.number
		species_rating()
		initialized = true
	end
end

local function filter(t1, t2)
	local out = {}
	local cache = {}
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

function M.SR_list(min, max)
	local n = {}

	for cr, list in pairs(sr) do 
		cr = tonumber(cr)
		if cr < max and cr > min then
			table.insert(n, cr)
		end
	end
	return n
end

function M.get_list(trainer_class, habitat, time_of_day)
	return filter(trainer_classes[trainer_class], habitats[habitat])
end

function M.habitat_list()
	local l = {}
	for t,_ in pairs(habitats) do
		table.insert(l, t)
	end

	return l
end

function M.trainer_class_list()
	return trainer_classes_list.Classes
end



return M