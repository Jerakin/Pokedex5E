local file = require "utils.file"
local natures = require "pokedex.natures"
local pokedex = require "pokedex.pokedex"
local utils = require "utils.utils"

local M = {}

local level_data

function M.level_data(level)
	return level_data[tostring(level)]
end

function M.init()
	level_data = file.load_json_from_resource("/assets/datafiles/leveling.json")
end

local STATS = {"STR", "DEX", "CON", "INT", "WIS", "CHA"}
local AVG_HIT_DIE = {[6]=4, [8]=5, [10]=6, [12]=7, [20]=12}

local function level_index(level)
	if level > 17 then
		return "17"
	elseif level > 10 then
		return "10"
	elseif level > 5 then
		return "5"
	else
		return "1"
	end
end

local function get_damage_mod_stab(pokemon, move)
	local modifier = 0
	local damage
	local ab
	local stab = false
	for _, mod in pairs(move.power) do
		if mod ~= "None" then
			modifier = pokemon.attributes[mod] > modifier and pokemon.attributes[mod] or modifier
		end
	end
	modifier = math.floor((modifier - 10) / 2)

	for _, t in pairs(pokemon.type) do
		if move.Type == t then
			STAB = pokemon.STAB
			stab = true
		end
	end
	local index  = level_index(pokemon.level)

	if move.Damage then
		damage = move.Damage[index].amount .. "d" .. move.Damage[index].dice_max
		if move.Damage[index].move then
			damage = damage .. "+" .. (modifier+STAB)
		end
		ab = modifier + pokemon.proficiency
	end
	return damage, modifier, stab
end

local function copy_move(move_name, old_data)
	local move = pokedex.get_move_data(move_name)
	local pokemon_move = old_data or {}
	pokemon_move.name = move_name
	pokemon_move.type =  move.Type
	pokemon_move.PP =  move.PP
	pokemon_move.duration = move.Duration
	pokemon_move.range = move.Range
	pokemon_move.description = move.Description
	pokemon_move.power = move["Move Power"]
	pokemon_move.damage = move.Damage
	pokemon_move.save = move.Save
	pokemon_move.time = move["Move Time"]
	return pokemon_move
end

local function setup_moves(this)
	local m = {}
	for _, move_name in pairs(this.moves) do
		local move = copy_move(move_name)
		dmg, mod, stab = get_damage_mod_stab(this, move)
		
		move.current_pp = move.PP
		move.damage = dmg
		move.stab = stab
		if move.damage then
			move.AB = mod + this.proficiency
		end
		if move.save then
			move.save_dc = 8 + mod + this.proficiency
		end
		m[move_name] = move
	end
	
	this.moves = m
end

local function add_score_from_nature(pokemon)
	local data = natures.nature_data(pokemon.nature)
	for stat, num in pairs(data) do
		if pokemon.attributes[stat] then
			pokemon.attributes[stat] = pokemon.attributes[stat] + num
		end
	end
end

local function setup_abilities(pokemon)
	local a = {}
	for _, ability in pairs(pokemon.abilities) do
		a[ability] = pokedex.get_ability_description(ability)
	end
	pokemon.abilities = a
end

local function add_ac_from_nature(pokemon)
	local data = natures.nature_data(pokemon.nature)
	if data["AC"] then
		pokemon.AC = pokemon.AC + data["AC"]
	end
end

local function setup_saving_throws(pokemon)
	local this = {}
	this.STR = pokemon.attributes.STR
	this.DEX = pokemon.attributes.DEX
	this.CON = pokemon.attributes.CON
	this.INT = pokemon.attributes.INT
	this.WIS = pokemon.attributes.WIS
	this.CHA = pokemon.attributes.CHA
	if pokemon.raw_data.ST1 then
		this[pokemon.raw_data.ST1] = this[pokemon.raw_data.ST1] + pokemon.proficiency
		if pokemon.raw_data.ST2 then
			this[pokemon.raw_data.ST2] = this[pokemon.raw_data.ST2] + pokemon.proficiency
			if pokemon.raw_data.ST3 then
				this[pokemon.raw_data.ST3] = this[pokemon.raw_data.ST3] + pokemon.proficiency
			end
		end
	end
	pokemon.saving_throw = this
end


local function update_attributes(pokemon)
	pokemon.attributes = {}
	pokemon.attributes.STR = pokemon.increased_attributes.STR + pokemon.base_attributes.STR
	pokemon.attributes.DEX = pokemon.increased_attributes.DEX + pokemon.base_attributes.DEX
	pokemon.attributes.CON = pokemon.increased_attributes.CON + pokemon.base_attributes.CON
	pokemon.attributes.INT = pokemon.increased_attributes.INT + pokemon.base_attributes.INT
	pokemon.attributes.WIS = pokemon.increased_attributes.WIS + pokemon.base_attributes.WIS
	pokemon.attributes.CHA = pokemon.increased_attributes.CHA + pokemon.base_attributes.CHA
	add_score_from_nature(pokemon)
end

local function update_moves(this)
	for move_name, data in pairs(this.moves) do
		data = copy_move(move_name, data)
		damage, ab, stab = get_damage_mod_stab(this, data)
		data.damage = damage
		data.stab = stab
		if data.damage then
			data.AB = mod + this.proficiency
		end
		if data.save then
			data.save_dc = 8 + mod + this.proficiency
		end
	end
end

function M.update_pokemon(pokemon)
	update_attributes(pokemon)
	update_moves(pokemon)
end

function M.decrease_move_pp(pokemon, move)
	pokemon.moves[move].current_pp = math.max(pokemon.moves[move].current_pp - 1, 0)
end

function M.reset_move_pp(pokemon, move)
	pokemon.moves[move].current_pp = pokemon.moves[move].PP
end

function M.set_current_hp(pokemon, hp)
	pokemon.current_hp = math.min(math.max(hp, 0), pokemon.HP)
end

function M.new(pokemon, id)
	this = {}
	this.id = id
	this.species = pokemon.species
	this.level = pokemon.level
	this.nature = pokemon.nature
	this.moves = pokemon.moves
	this.raw_data = pokedex.get_pokemon(pokemon.species)
	this.AC = this.raw_data.AC
	
	this.base_attributes = {}
	this.base_attributes.STR = this.raw_data.STR
	this.base_attributes.DEX = this.raw_data.DEX
	this.base_attributes.CON = this.raw_data.CON
	this.base_attributes.INT = this.raw_data.INT
	this.base_attributes.WIS = this.raw_data.WIS
	this.base_attributes.CHA = this.raw_data.CHA

	this.increased_attributes = {}
	this.increased_attributes.STR = pokemon.STR
	this.increased_attributes.DEX = pokemon.DEX
	this.increased_attributes.CON = pokemon.CON
	this.increased_attributes.INT = pokemon.INT
	this.increased_attributes.WIS = pokemon.WIS
	this.increased_attributes.CHA = pokemon.CHA

	this.skills = this.raw_data.Skill or {}
	this.type = this.raw_data.Type
	this.resistances = this.raw_data.Res
	this.vulnerabilities = this.raw_data.Vul
	this.immunities = this.raw_data.Imm
	this.abilities = this.raw_data.Abilities
	this.HP = this.raw_data.HP
	this.current_hp = this.HP
	this.proficiency = M.level_data(this.level).prof
	this.STAB = M.level_data(this.level).STAB
	
	update_attributes(this)
	add_ac_from_nature(this)
	setup_saving_throws(this)
	setup_abilities(this)
	setup_moves(this)
	this.raw_data = nil
	return this
end

return M