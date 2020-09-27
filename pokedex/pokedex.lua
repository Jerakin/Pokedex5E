local file = require "utils.file"
local utils = require "utils.utils"
local movedex = require "pokedex.moves"
local log = require "utils.log"
local fakemon = require "fakemon.fakemon"
local dex_data = require "pokedex.dex_data"
local ptypes = require "ptypes.main"
local trainer = require "pokedex.trainer"


local M = {}

local pokedex
local pokedex_variants
local pokedex_extra
local abilities = {}
local evolvedata
local evolve_from_data = {}
local leveldata
local exp_grid
local genders

M.GENDERLESS = 0
M.MALE = 1
M.FEMALE = 2

local initialized = false
local function list()
	local _index_list = file.load_json_from_resource("/assets/datafiles/index_order.json")
	local index_list = {}
	local unique = {}
	local index = 1
	while true do
		if _index_list[tostring(index)] then
			if not index_list[index] then
				unique[index] = _index_list[tostring(index)][1]
			end
			index_list[index] = _index_list[tostring(index)]
			index = index + 1
		else
			break
		end
	end
	-- Add fakemons
	for species, data in pairs(pokedex) do
		index = data.index
		if index > 0 then
			if not index_list[index] then
				unique[index] = species
				index_list[index] = {}
			end
			table.insert(index_list[index], species)
		end
	end

	-- Create the order top to down
	index = 1
	local order = {}
	for _, pokemons in pairs(index_list) do
		for _, species in pairs(pokemons) do
			order[index] = species
			index = index + 1
		end
	end

	return order, #order, unique
	
end

local function cache_evolve_from_data()
	for species, data in pairs(evolvedata) do
		if data.into then
			for _, into in pairs(data.into) do
				evolve_from_data[into] = species
			end
		end
	end
end

local warning_list = {}
local function get_pokemon_raw(pokemon)
	if pokedex[pokemon] then
		return utils.deep_copy(pokedex[pokemon])
	else
		local pokemon_species = pokemon:gsub(" ♀", "-f")
		pokemon_species = pokemon_species:gsub(" ♂", "-m")
		pokemon_species = pokemon_species:gsub("é", "e")
		local pokemon_json = file.load_json_from_resource("/assets/datafiles/pokemon/".. pokemon_species .. ".json")
		if pokemon_json ~= nil then
			pokedex[pokemon] = pokemon_json
			return utils.deep_copy(pokedex[pokemon])
		else
			local e = string.format("Can not find Pokemon: '%s'\n%s", tostring(pokemon), debug.traceback())
			if not warning_list[tostring(pokemon)] then
				gameanalytics.addErrorEvent {
					severity = "Critical",
					message = e
				}
				log.error(e)
			end
			warning_list[tostring(pokemon)] = true
			return pokedex["MissingNo"]
		end
	end
end

function M.init()
	if not initialized then
		pokedex = {}
		pokedex_variants = {}
		pokedex["MissingNo"] = file.load_json_from_resource("/assets/datafiles/pokemon/MissingNo.json")
		pokedex_extra = file.load_json_from_resource("/assets/datafiles/pokedex_extra.json")
		abilities = file.load_json_from_resource("/assets/datafiles/abilities.json")
		evolvedata = file.load_json_from_resource("/assets/datafiles/evolve.json")
		cache_evolve_from_data()
		leveldata = file.load_json_from_resource("/assets/datafiles/leveling.json")
		exp_grid = file.load_json_from_resource("/assets/datafiles/exp_grid.json")
		genders = file.load_json_from_resource("/assets/datafiles/gender.json")
		if fakemon.DATA then
			if fakemon.DATA["pokemon.json"] then
				log.info("Merging Pokemon data")
				for pokemon, data in pairs(fakemon.DATA["pokemon.json"]) do
					log.info("  " .. pokemon)
					data.fakemon = true
					pokedex[pokemon] = data
				end
			end
			if fakemon.DATA["pokedex_extra.json"] then
				for name, data in pairs(fakemon.DATA["pokedex_extra.json"]) do
					pokedex_extra[name] = data
				end
			end
			if fakemon.DATA["abilities.json"] then
				for name, data in pairs(fakemon.DATA["abilities.json"]) do
					abilities[name] = data
				end
			end
			if fakemon.DATA["evolve.json"] then
				for name, data in pairs(fakemon.DATA["evolve.json"]) do
					evolvedata[name] = data
				end
			end
			if fakemon.DATA["gender.json"] then
				for name, data in pairs(fakemon.DATA["gender.json"]) do
					genders[name] = data
				end
			end
		end
		M.list, M.total, M.unique = list()
		initialized = true
	else
		local e = "The pokedex have already been initialized"
		gameanalytics.addErrorEvent {
			severity = "Warning",
			message = e
		}
		log.warning(e)
	end
end


local function dex_extra(pokemon)
	local pokemon_index = M.get_index_number(pokemon)
	local mon = pokedex_extra[tostring(pokemon_index)]
	if not mon then
		log.error("Can't find extra information for " .. tostring(pokemon))
	end
	return mon or pokedex_extra["MissingNo"]
end


function M.genderized(pokemon)
	local g = genders[pokemon]
	return g~=nil, g
end


function M.get_flavor(pokemon)
	return dex_extra(pokemon).flavor
end


function M.get_weight(pokemon)
	return dex_extra(pokemon).weight
end


function M.get_height(pokemon)
	return dex_extra(pokemon).height
end


function M.get_genus(pokemon)
	return dex_extra(pokemon).genus
end


function M.get_current_evolution_stage(pokemon)
	local data = M.get_evolution_data(pokemon)
	return data and data.current_stage or 1
end


function M.get_total_evolution_stages(pokemon)
	local data = M.get_evolution_data(pokemon)
	return data and data.total_stages or 1
end


function M.get_variants(pokemon)
	local raw = get_pokemon_raw(pokemon)
	if raw.Variants then
		local ret = {}
		for k,_ in pairs(raw.Variants) do
			table.insert(ret, k)
		end
		return ret
	end
	return nil
end


function M.get_default_variant(pokemon)
	local raw = get_pokemon_raw(pokemon)
	if raw.Variants then
		for k,v in pairs(raw.Variants) do
			if v.Default then
				return k
			end
		end
	end
	return nil
end


function M.get_species_display(pokemon, variant)
	if variant then
		local raw = get_pokemon_raw(pokemon)
		if raw.Variants then
			var_data = raw.Variants[variant]
			if var_data and var_data.Display then
				return var_data.Display
			end
		end
	end
	return pokemon
end


function M.get_icon(pokemon, variant)
	local data = M.get_pokemon(pokemon, variant)
	local sprite = M.get_sprite(pokemon)
	if data.fakemon then
		if data.icon and data.icon ~= "" then
			local path = fakemon.UNZIP_PATH .. utils.os_sep .. data.icon 
			local file = io.open(path, "rb")
			if not file then
				return "-1MissingNo", "sprite0"
			end
			local buffer = file:read("*all")
			file:close()
			local img = image.load(buffer, true)

			gui.new_texture("icon" .. pokemon, img.width, img.height, img.type, img.buffer, false)
			return nil, "icon" .. pokemon
		elseif data.index < dex_data.max_index[#dex_data.order -1] then
			return sprite, "sprite0"
		end
		return "-2Pokeball", "sprite0"
	end
	
	
	return sprite, "sprite0"
end


function M.get_sprite(pokemon, variant)
	local pokemon_index = M.get_index_number(pokemon)
	if pokemon_index == -1 then
		return "-1MissingNo", "pokemon0"
	end
	local pokemon_sprite = pokemon_index .. pokemon
	
	if pokemon_index == 32 or pokemon_index == 29 or pokemon_index == 678 then
		pokemon_sprite = pokemon_sprite:gsub(" ♀", "-f")
		pokemon_sprite = pokemon_sprite:gsub(" ♂", "-m")
	elseif pokemon_index == 493 then
		return "493Arceus", "pokemon0"
	end

	local data = M.get_pokemon(pokemon, variant)
	if data.fakemon then
		if data.sprite and data.sprite ~= "" then
			local path = fakemon.UNZIP_PATH .. utils.os_sep .. data.sprite 
			local file = io.open(path, "rb")
			if not file then
				return "-1MissingNo", "pokemon0"
			end
			local buffer = file:read("*all")
			file:close()
			local img = image.load(buffer)

			gui.new_texture("sprite" .. pokemon, img.width, img.height, img.type, img.buffer, false)
			return nil, "sprite" ..  pokemon
		elseif data.index < dex_data.max_index[#dex_data.order -1] then
			return pokemon_index .. pokemon, "pokemon0"
		end
		return "-2Pokeball", "pokemon0"
	end
	return pokemon_sprite, "pokemon0"
end


function M.level_data(level)
	if leveldata[tostring(level)] then
		return leveldata[tostring(level)]
	end
	log.error("Can not find level data for: " .. tostring(level))
end


function M.get_experience_for_level(level)
	return M.level_data(level).exp
end


function M.get_senses(pokemon, variant)
	return M.get_pokemon(pokemon, variant).Senses or {}
end


function M.get_index_number(pokemon, variant)
	return M.get_pokemon(pokemon, variant).index
end


function M.get_vulnerabilities(pokemon, variant)
	local types = M.get_pokemon_type(pokemon, variant)
	return ptypes.Model(unpack(types)).vulnerabilities
end


function M.get_immunities(pokemon)
	local types = M.get_pokemon_type(pokemon)
	return ptypes.Model(unpack(types)).immunities
end


function M.get_resistances(pokemon)
	local types = M.get_pokemon_type(pokemon)
	return ptypes.Model(unpack(types)).resistances
end


function M.get_walking_speed(pokemon, variant)
	return M.get_pokemon(pokemon, variant).WSp or 0
end


function M.get_swimming_speed(pokemon, variant)
	return M.get_pokemon(pokemon, variant).Ssp or 0
end


function M.get_flying_speed(pokemon, variant)
	return M.get_pokemon(pokemon, variant).Fsp or 0
end


function M.get_climbing_speed(pokemon, variant)
	return M.get_pokemon(pokemon, variant)["Climbing Speed"] or 0
end


function M.get_burrow_speed(pokemon, variant)
	return M.get_pokemon(pokemon, variant)["Burrowing Speed"] or 0
end

function M.get_pokemon_type(pokemon, variant)
	return M.get_pokemon(pokemon, variant).Type
end

function M.get_pokemon_size(pokemon, variant)
	return M.get_pokemon(pokemon, variant).size or ""
end

function M.ability_list()
	local l = {}
	for a, _ in pairs(abilities) do 
		table.insert(l, a)
	end
	return l
end


function M.get_ability_description(ability)
	if abilities[ability] then
		return abilities[ability].Description
	else
		local e = string.format("Can not find Ability: '%s'", tostring(ability))  .. "\n" .. debug.traceback()
		gameanalytics.addErrorEvent {
			severity = "Error",
			message = e
		}
		log.error(e)
		return "This is an error, the app couldn't find the ability"
	end
end


function M.get_hidden_ability(pokemon, variant)
	return M.get_pokemon(pokemon, variant)["Hidden Ability"]
end


function M.get_abilities(pokemon, variant)
	return M.get_pokemon(pokemon, variant).Abilities
end


function M.get_skills(pokemon, variant)
	return M.get_pokemon(pokemon, variant).Skill
end


function M.get_base_hp(pokemon, variant)
	local min_lvl = M.get_minimum_wild_level(pokemon)
	local con = M.get_base_attributes(pokemon, variant).CON
	local con_mod = math.floor((con - 10) / 2)
	return M.get_pokemon(pokemon, variant).HP - (min_lvl * con_mod)
end


function M.get_AC(pokemon, variant)
	return M.get_pokemon(pokemon, variant).AC
end


function M.get_pokemon(pokemon, variant)
	local raw = get_pokemon_raw(pokemon)

	-- Default case: no variant provided, pokemon has no variants, or pokemon does not have provided variant
	if not variant or not raw.Variants or not raw.Variants[variant] then
		return raw
	end

	-- Alright, this pokemon has this variant, we need to get the data for this specific variant, which could have any number of overrides
	if not pokedex_variants[pokemon] then
		pokedex_variants[pokemon] = {}
	end
	if not pokedex_variants[pokemon][variant] then
		local copy = utils.deep_copy(raw)
		copy["Variants"] = nil
		local diff = raw.Variants[variant].Diff
		utils.deep_merge_into(copy, diff)
		pokedex_variants[pokemon][variant] = copy
	end
	return pokedex_variants[pokemon][variant]
end


function M.get_minimum_wild_level(pokemon, variant)
	return M.get_pokemon(pokemon, variant)["MIN LVL FD"]
end


function M.get_evolution_data(pokemon)
	if evolvedata[pokemon] then
		return evolvedata[pokemon]
	end
	log.info("Can not find evolution data for pokemon : " .. tostring(pokemon))
end


function M.get_evolved_from(pokemon)
	return evolve_from_data[pokemon]
end

function M.get_evolution_possible(pokemon, gender, moves)
	local d = M.get_evolution_data(pokemon)
	local gender_allow = false
	local move_allow = true
	if d and d.move then
		move_allow = false
		for move, _ in pairs(moves) do
			if d.move == move then
				move_allow = true
			end
		end
	end

	if d and d.into then
		for _, species in pairs(d.into) do
			if genders[species] == nil or (genders[species] and genders[species] == (gender or M.GENDERLESS)) then
				gender_allow = true
			end
		end
	end
	return (d and move_allow and gender_allow) and true or false
end

function M.get_species_can_evolve(pokemon)
	local d = M.get_evolution_data(pokemon)
	return d and d.into and next(d.into) ~= nil
end

function M.get_evolution_level(pokemon)
	-- Pokemon can evolve at any level (set it to 1) as long as they have the move
	-- if they do not evolve based on move then use the standard level
	
	local d = M.get_evolution_data(pokemon)
	return d.level ~= nil and d.level + trainer.get_evolution_level() or 1
end


function M.get_evolutions(pokemon, gender)
	local d = M.get_evolution_data(pokemon)
	local evolutions = {}
	for _, species in pairs(d.into) do
		if genders[species] == nil or (genders[species] and genders[species] == (gender or M.GENDERLESS)) then
			table.insert(evolutions, species)
		end
	end
	return evolutions
end


function M.evolve_points(pokemon)
	local d = M.get_evolution_data(pokemon)
	return d and d.points or 0
end


function M.get_starting_moves(pokemon, variant)
	return M.get_pokemon(pokemon, variant)["Moves"]["Starting Moves"]
end


function M.get_base_attributes(pokemon, variant)
	return M.get_pokemon(pokemon, variant).attributes
end


function M.get_saving_throw_proficiencies(pokemon, variant)
	return M.get_pokemon(pokemon, variant).saving_throws
end


function M.get_hit_dice(pokemon, variant)
	return M.get_pokemon(pokemon, variant)["Hit Dice"]
end


function M.get_HM_numbers(pokemon, variant)
	return M.get_pokemon(pokemon, variant)["Moves"].HM
end


function M.get_TM_numbers(pokemon, variant)
	return M.get_pokemon(pokemon, variant)["Moves"].TM
end


function M.get_move_machines(pokemon, variant)
	local move_list = {}
	local tm_numbers = M.get_pokemon_TM_numbers(pokemon, variant)
	if tm_numbers then
		for _, n in pairs(tm_numbers) do
			table.insert(move_list, movedex.get_TM(n))
		end
	end
	return move_list
end


function M.get_SR(pokemon, variant)
	return M.get_pokemon(pokemon, variant).SR
end


function M.get_exp_worth(level, sr)
	return exp_grid[level][sr]
end


function M.get_moves(pokemon, variant, level)
	level = level or 20
	local moves = M.get_pokemon(pokemon)["Moves"]
	local pick_from = utils.shallow_copy(moves["Starting Moves"])
	for l, move in pairs(moves["Level"]) do
		if level >= tonumber(l) then
			for _, m in pairs(move) do
				table.insert(pick_from, m)
			end
		end
	end
	return pick_from
end


return M