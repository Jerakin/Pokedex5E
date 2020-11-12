local file = require "utils.file"
local utils = require "utils.utils"
local movedex = require "pokedex.moves"
local log = require "utils.log"
local fakemon = require "fakemon.fakemon"
local dex_data = require "pokedex.dex_data"
local ptypes = require "ptypes.main"
local trainer = require "pokedex.trainer"
local settings = require "pokedex.settings"


local M = {}

local pokedex
local pokedex_variants
local pokedex_original_species_map
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
M.ANY = 3

M.VARIANT_CREATE_MODE_DEFAULT = "default"
M.VARIANT_CREATE_MODE_CHOOSE = "choose"

M.skills = {
	'Acrobatics', 'Animal Handling', 'Arcana', 'Athletics',
	'Deception', 'History', 'Insight', 'Intimidation',
	'Investigation', 'Medicine', 'Nature', 'Perception', 'Performance',
	'Persuasion', 'Religion', 'Sleight of Hand', 'Stealth', 'Survival'
}

local initialized = false
local function list()
	local _index_list = file.load_json_from_resource("/assets/datafiles/index_order.json")
	local index_list = {}
	local index_table = {}
	local unique = {}
	local index = 1
	while true do
		if _index_list[tostring(index)] then
			if not index_list[index] then
				unique[index] = _index_list[tostring(index)][1]
			end
			index_list[index] = _index_list[tostring(index)]
			index_table[index] = {}
			for i=1,#index_list[index] do
				index_table[index][index_list[index][i]] = true
			end
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
				index_table[index] = {}
			end
			if not index_table[index][species] then
				index_table[index][species] = true
				table.insert(index_list[index], species)
			end
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
		pokemon_species = pokemon_species:gsub(":", "")
		local pokemon_json = file.load_json_from_resource("/assets/datafiles/pokemon/".. pokemon_species .. ".json")
		if pokemon_json ~= nil then
			pokedex[pokemon] = pokemon_json
			return utils.deep_copy(pokedex[pokemon])
		else
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
		leveldata = file.load_json_from_resource("/assets/datafiles/leveling.json")
		exp_grid = file.load_json_from_resource("/assets/datafiles/exp_grid.json")
		genders = file.load_json_from_resource("/assets/datafiles/gender.json")

		local f_overrides, f_variants = fakemon.get_overrides_and_variants()
		if next(f_overrides) or next(f_variants) then
			log.info("Merging Pokemon data")
			for pokemon, data in pairs(f_overrides) do
				log.info("  " .. pokemon)
				pokedex[pokemon] = data
			end
			for pokemon, f_vars in pairs(f_variants) do
				for variant, data in pairs(f_vars) do
					log.info("  " .. pokemon .. " - " .. variant)
					if not pokedex_variants[pokemon] then
						pokedex_variants[pokemon] = {}
					end
					pokedex_variants[pokemon][variant] = data
				end
			end
		end

		if fakemon.DATA then
			if fakemon.DATA["pokedex_extra.json"] then
				for name, data in pairs(fakemon.DATA["pokedex_extra.json"]) do
					pokedex_extra[name] = data
				end
			end
			if fakemon.DATA["abilities.json"] then
				log.info("Merging abilities data")
				for name, data in pairs(fakemon.DATA["abilities.json"]) do
					log.info("  " .. name)
					abilities[name] = data
				end
			end
			if fakemon.DATA["evolve.json"] then
				log.info("Merging evolve data")
				for name, data in pairs(fakemon.DATA["evolve.json"]) do
					if pokedex[name] then
						log.info("  " .. name)
						evolvedata[name] = data
					else
						log.info("  " .. name .. " (does not exist, skipped)")
					end
				end
			end
			if fakemon.DATA["gender.json"] then
				log.info("Merging gender data")
				for name, data in pairs(fakemon.DATA["gender.json"]) do
					log.info("  " .. name)
					genders[name] = data
				end
			end
		end
		
		cache_evolve_from_data()
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

function M.enforce_genders()
	return settings.get("strict_gender", false)
end


function M.get_strict_gender(pokemon)
	return genders[pokemon] or M.ANY
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


function M.has_variants(pokemon)
	local raw = get_pokemon_raw(pokemon)
	if raw.variant_data and raw.variant_data.variants and next(raw.variant_data.variants) then
		return true
	end
	return false
end


function M.get_variants(pokemon)
	local raw = get_pokemon_raw(pokemon)
	if raw.variant_data and raw.variant_data.variants then
		local ret = {}
		for k,_ in pairs(raw.variant_data.variants) do
			table.insert(ret, k)
		end
		return ret
	end
	return nil
end


function M.get_variant_create_mode(pokemon)
	local raw = get_pokemon_raw(pokemon)
	if raw.variant_data then
		if raw.variant_data.create_mode == M.VARIANT_CREATE_MODE_CHOOSE then
			return M.VARIANT_CREATE_MODE_CHOOSE
		end
	end
	return M.VARIANT_CREATE_MODE_DEFAULT
end


function M.get_default_variant(pokemon)
	local raw = get_pokemon_raw(pokemon)
	return raw.variant_data and raw.variant_data.default or nil
end


function M.get_variant_from_original_species(pokemon, original_species)

	if not pokedex_original_species_map then
		pokedex_original_species_map = {}
	end
	if not pokedex_original_species_map[pokemon] then
		pokedex_original_species_map[pokemon] = {}

		-- Cache off a mapping of original species -> variant name
		local data = get_pokemon_raw(pokemon)
		if data.variant_data and data.variant_data.variants then
			for v, var_obj in pairs(data.variant_data.variants) do
				if var_obj.original_species then
					pokedex_original_species_map[pokemon][var_obj.original_species] = v
				end
			end
		end
	end

	return pokedex_original_species_map[pokemon][original_species]
end


function M.get_species_display(pokemon, variant)
	if variant then
		local raw = get_pokemon_raw(pokemon)
		if raw.variant_data and raw.variant_data.variants then
			var_data = raw.variant_data.variants[variant]
			if var_data and var_data.display then
				return var_data.display
			end
		end
	end
	return pokemon
end


function M.get_icon(pokemon, variant)
	local data = M.get_pokemon(pokemon, variant)
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

			local icon_name = "icon" .. pokemon .. (variant or "")
			gui.new_texture(icon_name, img.width, img.height, img.type, img.buffer, false)
			return nil, icon_name
		elseif data.index >= dex_data.max_index[#dex_data.order -1] then
			return "-2Pokeball", "sprite0"
		end
	end
	
	local sprite = M.get_sprite(pokemon, variant)
	return sprite, "sprite0"
end


function M.get_sprite(pokemon, variant)
	local pokemon_index = M.get_index_number(pokemon)
	if pokemon_index == -1 then
		return "-1MissingNo", "pokemon0"
	end

	local sprite_suffix = pokemon

	local raw_data = get_pokemon_raw(pokemon)
	if raw_data.variant_data then
		current_variant = variant or raw_data.variant_data.default
		if raw_data.variant_data.sprite_suffix then
			sprite_suffix = raw_data.variant_data.sprite_suffix
		elseif raw_data.variant_data.variants and raw_data.variant_data.variants[current_variant] and raw_data.variant_data.variants[current_variant].original_species then
			sprite_suffix = raw_data.variant_data.variants[current_variant].original_species
		end
	end

	local pokemon_sprite = pokemon_index .. sprite_suffix
	
	if pokemon_index == 32 or pokemon_index == 29 or pokemon_index == 678 or pokemon_index == 772 then
		pokemon_sprite = pokemon_sprite:gsub(" ♀", "-f")
		pokemon_sprite = pokemon_sprite:gsub(" ♂", "-m")
		pokemon_sprite = pokemon_sprite:gsub(":", "")
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

			local sprite_name = "sprite" .. pokemon .. (variant or "")
			gui.new_texture(sprite_name, img.width, img.height, img.type, img.buffer, false)
			return nil, sprite_name
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


function M.get_index_number(pokemon)
	return get_pokemon_raw(pokemon).index
end


function M.get_vulnerabilities(pokemon, variant)
	local types = M.get_pokemon_type(pokemon, variant)
	return ptypes.Model(unpack(types)).vulnerabilities
end


function M.get_immunities(pokemon, variant)
	local types = M.get_pokemon_type(pokemon, variant)
	return ptypes.Model(unpack(types)).immunities
end


function M.get_resistances(pokemon, variant)
	local types = M.get_pokemon_type(pokemon, variant)
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
	if not variant or not raw.variant_data or not raw.variant_data.variants or not raw.variant_data.variants[variant] then
		return raw
	end

	-- Alright, this pokemon has this variant, we need to get the data for this specific variant, which could have any number of overrides
	if not pokedex_variants[pokemon] then
		pokedex_variants[pokemon] = {}
	end
	if not pokedex_variants[pokemon][variant] then
		local copy = utils.deep_copy(raw)
		copy["variant_data"] = nil
		local diff = raw.variant_data.variants[variant].diff
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
	if M.enforce_genders() then
		if d and d.into then
			for _, species in pairs(d.into) do
			if genders[species] == nil or (genders[species] and genders[species] == (gender or M.GENDERLESS)) then
					gender_allow = true
				end
			end
		end
	else
		gender_allow = true
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
		if not M.enforce_genders() then
			table.insert(evolutions, species)
		elseif genders[species] == nil or (genders[species] and genders[species] == gender) then
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


function M.get_hit_dice(pokemon)
	return get_pokemon_raw(pokemon)["Hit Dice"]
end


function M.get_HM_numbers(pokemon, variant)
	return M.get_pokemon(pokemon, variant)["Moves"].HM
end


function M.get_TM_numbers(pokemon, variant)
	return M.get_pokemon(pokemon, variant)["Moves"].TM
end


function M.get_move_machines(pokemon, variant)
	local move_list = {}
	local tm_numbers = M.get_TM_numbers(pokemon, variant)
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

function M.get_egg_moves(pokemon, variant)
	local moves = M.get_pokemon(pokemon, variant)["Moves"]
	local pick_from = utils.shallow_copy(moves["egg"]) or {}
	return pick_from
end


function M.get_moves(pokemon, variant, level)
	level = level or 20
	local moves = M.get_pokemon(pokemon, variant)["Moves"]
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