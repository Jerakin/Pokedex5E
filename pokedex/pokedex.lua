local file = require "utils.file"
local utils = require "utils.utils"
local movedex = require "pokedex.moves"
local log = require "utils.log"
local fakemon = require "fakemon.fakemon"

local M = {}

local pokedex
local pokedex_extra
local abilities = {}
local evolvedata
local leveldata
local exp_grid

local initialized = false
local function list()
	local temp = {}

	-- Group based on index and create unique list
	local unique = {}
	for species, data in pairs(pokedex) do
		local index = data.index
		if index > 0 then
			if not temp[index] then
				unique[index] = species
				temp[index] = {}
			end
			table.insert(temp[index], species)
		end
	end
	
	-- Create the order top to down
	local index = 1
	local order = {}
	for _, pokemons in pairs(temp) do
		for _, species in pairs(pokemons) do
			order[index] = species
			index = index + 1
		end
	end

	return order, #order, unique
end

function M.get_whole_pokedex()
	return pokedex
end

function M.init()
	if not initialized then
		pokedex = file.load_json_from_resource("/assets/datafiles/pokemon.json")
		pokedex_extra = file.load_json_from_resource("/assets/datafiles/pokedex_extra.json")
		abilities = file.load_json_from_resource("/assets/datafiles/abilities.json")
		evolvedata = file.load_json_from_resource("/assets/datafiles/evolve.json")
		leveldata = file.load_json_from_resource("/assets/datafiles/leveling.json")
		exp_grid = file.load_json_from_resource("/assets/datafiles/exp_grid.json")

		if fakemon.pokemon then
			for pokemon, data in pairs(fakemon.pokemon) do
				pokedex[pokemon] = data
			end
		end
		if fakemon.pokedex_extra then
			for name, data in pairs(fakemon.pokedex_extra) do
				pokedex_extra[name] = data
			end
		end
		if fakemon.abilities then
			for name, data in pairs(fakemon.abilities) do
				abilities[name] = data
			end
		end
		if fakemon.evolve then
			evolvedata = fakemon.evolve
		end
		if fakemon.leveling then
			for name, data in pairs(fakemon.leveling) do
				leveling[name] = data
			end
		end
		if fakemon.exp_grid then
			exp_grid = fakemon.exp_grid
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

function M.get_icon(pokemon)
	local data = M.get_pokemon(pokemon)
	if data.sprite then
		local path = fakemon.APP_ROOT .. fakemon.PACKAGE_NAME .. utils.os_sep .. data.icon 
		local file = io.open(path, "rb")
		if not file then
			return "-1MissingNo", "pokemon0"
		end
		local buffer = file:read("*all")
		file:close()
		local img = image.load(buffer, true)

		gui.new_texture("icon" .. pokemon, img.width, img.height, img.type, img.buffer, false)
		return nil, "icon" .. pokemon
	end
	
	local sprite = M.get_sprite(pokemon)
	return sprite, "sprite0"
end

function M.get_sprite(pokemon)
	local pokemon_index = M.get_index_number(pokemon)
	if pokemon_index == -1 then
		return "-1MissingNo", "pokemon0"
	end
	local pokemon_sprite = pokemon_index .. pokemon
	if pokemon_index == 32 or pokemon_index == 29 then
		pokemon_sprite = pokemon_sprite:sub(1, -5)
	elseif pokemon_index == 493 then
		return "493Arceus", "pokemon0"
	end

	local data = M.get_pokemon(pokemon)
	if data.sprite then
		local path = fakemon.APP_ROOT .. fakemon.PACKAGE_NAME .. utils.os_sep .. data.sprite 
		local file = io.open(path, "rb")
		if not file then
			return "-1MissingNo", "pokemon0"
		end
		local buffer = file:read("*all")
		file:close()
		local img = image.load(buffer)

		gui.new_texture("sprite" .. pokemon, img.width, img.height, img.type, img.buffer, false)
		return nil, "sprite" ..  pokemon
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

function M.get_senses(pokemon)
	return M.get_pokemon(pokemon).Senses or {}
end

function M.get_index_number(pokemon)
	return M.get_pokemon(pokemon).index
end

function M.get_pokemon_vulnerabilities(pokemon)
	return M.get_pokemon(pokemon).Vul
end

function M.get_pokemon_immunities(pokemon)
	return M.get_pokemon(pokemon).Imm
end

function M.get_pokemon_resistances(pokemon)
	return M.get_pokemon(pokemon).Res
end

function M.get_walking_speed(pokemon)
	return M.get_pokemon(pokemon).WSp or 0
end

function M.get_swimming_speed(pokemon)
	return M.get_pokemon(pokemon).Ssp or 0
end

function M.get_flying_speed(pokemon)
	return M.get_pokemon(pokemon).Fsp or 0
end

function M.get_climbing_speed(pokemon)
	return M.get_pokemon(pokemon)["Climbing Speed"] or 0
end

function M.get_pokemon_type(pokemon)
	return M.get_pokemon(pokemon).Type
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

function M.get_pokemon_hidden_ability(pokemon)
	return M.get_pokemon(pokemon)["Hidden Ability"]
end

function M.get_pokemon_abilities(pokemon)
	return M.get_pokemon(pokemon).Abilities
end

function M.get_pokemon_skills(pokemon)
	return M.get_pokemon(pokemon).Skill
end

function M.get_base_hp(pokemon)
	local min_lvl = M.get_minimum_wild_level(pokemon)
	local con = M.get_base_attributes(pokemon).CON
	local con_mod = math.floor((con - 10) / 2)
	return M.get_pokemon(pokemon).HP - (min_lvl * con_mod)
end


function M.get_pokemon_AC(pokemon)
	return M.get_pokemon(pokemon).AC
end

function M.get_pokemon(pokemon)
	if pokedex[pokemon] then
		return utils.deep_copy(pokedex[pokemon])
	else
		local e = string.format("Can not find Pokemon: '%s'\n\n%s", tostring(pokemon), debug.traceback())
		gameanalytics.addErrorEvent {
			severity = "Critical",
			message = e
		}
		log.error(e)
		return pokedex["MissingNo"]
	end
end

function M.get_minimum_wild_level(pokemon)
	return M.get_pokemon(pokemon)["MIN LVL FD"]
end

function M.get_evolution_data(pokemon)
	if evolvedata[pokemon] then
		return evolvedata[pokemon]
	end
	log.info("Can not find evolution data for pokemon : " .. tostring(pokemon))
end

function M.get_evolved_from(pokemon)
	for species, data in pairs(evolvedata) do
		for _, into in pairs(data.into) do
			if into == pokemon then
				return species
			end
		end
	end
	return "MissingNo"
end

function M.get_evolution_possible(pokemon)
	return M.get_evolution_data(pokemon) or true and false
end

function M.get_evolution_level(pokemon)
	return M.get_evolution_data(pokemon).level
end

function M.get_evolutions(pokemon)
	return M.get_evolution_data(pokemon).into
end

function M.evolve_points(pokemon)
	return M.get_evolution_data(pokemon).points
end

function M.get_starting_moves(pokemon)
	return M.get_pokemon(pokemon)["Moves"]["Starting Moves"]
end

function M.get_base_attributes(pokemon)
	return M.get_pokemon(pokemon).attributes
end

function M.get_saving_throw_proficiencies(pokemon)
	return M.get_pokemon(pokemon).saving_throws
end

function M.get_pokemon_hit_dice(pokemon)
	return M.get_pokemon(pokemon)["Hit Dice"]
end

function M.get_pokemon_HM_numbers(pokemon)
	return M.get_pokemon(pokemon)["Moves"].HM
end

function M.get_pokemon_TM_numbers(pokemon)
	return M.get_pokemon(pokemon)["Moves"].TM
end

function M.get_move_machines(pokemon)
	local move_list = {}
	if M.get_pokemon_TM_numbers(pokemon) then
		for _, n in pairs(M.get_pokemon_TM_numbers(pokemon)) do
			table.insert(move_list, movedex.get_TM(n))
		end
	end
	return move_list
end

function M.get_pokemon_SR(pokemon)
	return M.get_pokemon(pokemon).SR
end

function M.get_pokemon_exp_worth(level, sr)
	return exp_grid[level][sr]
end

function M.get_pokemons_moves(pokemon, level)
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