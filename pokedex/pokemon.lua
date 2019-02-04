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
	local stab_damage = 0
	local total = M.get_total_attribute
	
	-- Pick the highest of the moves power
	local total = M.get_total_attributes(pokemon)
	for _, mod in pairs(move.power) do
		if total[mod] then
			modifier = total[mod] > modifier and total[mod] or modifier
		end
	end
	modifier = math.floor((modifier - 10) / 2)

	for _, t in pairs(pokemon.type) do
		if move.type == t and move.damage then
			stab_damage = pokemon.STAB
			stab = true
		end
	end
	local index  = level_index(pokemon.level)

	if move.damage then
		damage = move.damage[index].amount .. "d" .. move.damage[index].dice_max
		if move.damage[index].move then
			damage = damage .. "+" .. (modifier+stab_damage)
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

local function setup_nature_attributes(pokemon)
	local data = natures.nature_data(pokemon.nature)
	for stat, num in pairs(data) do
		if pokemon.attributes.nature[stat] then
			pokemon.attributes.nature[stat] = num
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
	local this = M.get_total_attributes(pokemon)
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

local function update_abilities(pokemon)
	local raw_pokemon = pokedex.get_pokemon(pokemon.species)
	pokemon.abilities = raw_pokemon.Abilities
	setup_abilities(pokemon)
end

local function update_moves(this)
	for move_name, data in pairs(this.moves) do
		data = copy_move(move_name, data)
		damage, mod, stab = get_damage_mod_stab(this, data)
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
	update_abilities(pokemon)
	setup_nature_attributes(pokemon)
	update_moves(pokemon)
end

function M.get_total_attributes(pokemon)
	local total = {}
	total.STR = pokemon.attributes.increased.STR + pokemon.attributes.base.STR + pokemon.attributes.nature.STR
	total.DEX = pokemon.attributes.increased.DEX + pokemon.attributes.base.DEX + pokemon.attributes.nature.DEX
	total.CON = pokemon.attributes.increased.CON + pokemon.attributes.base.CON + pokemon.attributes.nature.CON
	total.INT = pokemon.attributes.increased.INT + pokemon.attributes.base.INT + pokemon.attributes.nature.INT
	total.WIS = pokemon.attributes.increased.WIS + pokemon.attributes.base.WIS + pokemon.attributes.nature.WIS
	total.CHA = pokemon.attributes.increased.CHA + pokemon.attributes.base.CHA + pokemon.attributes.nature.CHA
	total.AC = pokemon.attributes.base.AC + pokemon.attributes.nature.AC
	return total
end

function M.edit(pokemon, pokemon_data)
	for i=#pokemon_data.moves, 1, -1 do
		if pokemon_data.moves[i] == "Move" then
			table.remove(pokemon_data.moves, i)
		end
	end
	pokemon.attributes.increased.STR = pokemon.attributes.increased.STR + pokemon_data.attributes.increased.STR
	pokemon.attributes.increased.DEX = pokemon.attributes.increased.DEX + pokemon_data.attributes.increased.DEX
	pokemon.attributes.increased.CON = pokemon.attributes.increased.CON + pokemon_data.attributes.increased.CON
	pokemon.attributes.increased.INT = pokemon.attributes.increased.INT + pokemon_data.attributes.increased.INT
	pokemon.attributes.increased.WIS = pokemon.attributes.increased.WIS + pokemon_data.attributes.increased.WIS
	pokemon.attributes.increased.CHA = pokemon.attributes.increased.CHA + pokemon_data.attributes.increased.CHA
	pokemon.moves = pokemon_data.moves
	
	pokemon.level = pokemon_data.level
	if pokemon.species ~= pokemon_data.species then
		pokemon.HP = pokemon.HP + (pokemon.level * 2)
		pokemon.species = pokemon_data.species
		
		local raw_pokemon = pokedex.get_pokemon(pokemon_data.species)
		pokemon.skills = raw_pokemon.Skill or {}
		pokemon.type = raw_pokemon.Type
		pokemon.resistances = raw_pokemon.Res
		pokemon.vulnerabilities = raw_pokemon.Vul
		pokemon.immunities = raw_pokemon.Imm
		pokemon.abilities = raw_pokemon.Abilities
		pokemon.attributes.base.AC = raw_pokemon.AC
	end
	setup_moves(pokemon)
	M.update_pokemon(pokemon)
end



function M.new(pokemon, id)
	this = {}
	this.id = id
	this.species = pokemon.species
	this.level = pokemon.level
	this.nature = pokemon.nature
	this.moves = pokemon.moves
	this.raw_data = pokedex.get_pokemon(pokemon.species)

	this.attributes = {}

	this.attributes.base = {}
	this.attributes.base.STR = this.raw_data.STR
	this.attributes.base.DEX = this.raw_data.DEX
	this.attributes.base.CON = this.raw_data.CON
	this.attributes.base.INT = this.raw_data.INT
	this.attributes.base.WIS = this.raw_data.WIS
	this.attributes.base.CHA = this.raw_data.CHA
	this.attributes.base.AC = this.raw_data.AC
	
	this.attributes.increased = {}
	this.attributes.increased.STR = pokemon.attributes.increased.STR
	this.attributes.increased.DEX = pokemon.attributes.increased.DEX
	this.attributes.increased.CON = pokemon.attributes.increased.CON
	this.attributes.increased.INT = pokemon.attributes.increased.INT
	this.attributes.increased.WIS = pokemon.attributes.increased.WIS
	this.attributes.increased.CHA = pokemon.attributes.increased.CHA

	this.attributes.nature = {}
	this.attributes.nature.STR = 0
	this.attributes.nature.DEX = 0
	this.attributes.nature.CON = 0
	this.attributes.nature.INT = 0
	this.attributes.nature.WIS = 0
	this.attributes.nature.CHA = 0
	this.attributes.nature.AC = 0
	
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

	setup_saving_throws(this)
	setup_abilities(this)
	setup_moves(this)
	this.raw_data = nil
	return this
end

return M