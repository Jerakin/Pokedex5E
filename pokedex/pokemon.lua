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

local function setup_moves(this)
	local m = {}
	for _, move_name in pairs(this.moves) do
		local move = pokedex.get_move_data(move_name)
		move.current_pp = move.PP
		move.STAB_MOVE = false
		local damage
		local modifier = 0
		local STAB = 0

		for _, mod in pairs(move["Move Power"]) do
			if mod ~= "None" then
				modifier = this[mod] > modifier and this[mod] or modifier
			end
		end
		modifier = math.floor((modifier - 10) / 2)

		for _, t in pairs(this.type) do
			if move.Type == t then
				STAB = this.STAB
				move.STAB_MOVE = true
			end
		end
		local index 
		if this.level > 17 then
			index = "17"
		elseif this.level > 10 then
			index = "10"
		elseif this.level > 5 then
			index = "5"
		else
			index = "1"
		end
		if move.Damage then
			damage = move.Damage[index].amount .. "d" .. move.Damage[index].dice_max
			if move.Damage[index].move then
				damage = damage .. "+" .. (modifier+STAB)
			end
			move.Damage = damage
			move["Attack Bonus"] = modifier + this.proficiency
		else
			move["Save DC"] = 8 + modifier + this.proficiency
		end
		m[move_name] = move
	end
	
	this.moves = m
end


local function add_score_from_nature(pokemon)
	local data = natures.nature_data(pokemon.nature)
	for stat, num in pairs(data) do
		pokemon[stat] = pokemon[stat] + num
	end
end

local function setup_abilities(pokemon)
	local a = {}
	for _, ability in pairs(pokemon.abilities) do
		a[ability] = pokedex.get_ability_description(ability)
	end
	pokemon.abilities = a
end

local function setup_saving_throws(pokemon)
	local this = {}
	this.STR = pokemon.STR
	this.DEX = pokemon.DEX
	this.CON = pokemon.CON
	this.INT = pokemon.INT
	this.WIS = pokemon.WIS
	this.CHA = pokemon.CHA
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


function M.decrease_move_pp(pokemon, move)
	pokemon.moves[move].current_pp = math.max(pokemon.moves[move].current_pp - 1, 0)
end

function M.reset_move_pp(pokemon, move)
	pokemon.moves[move].current_pp = pokemon.moves[move].PP
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
	this.STR = this.raw_data.STR + pokemon.STR
	this.DEX = this.raw_data.DEX + pokemon.DEX
	this.CON = this.raw_data.CON + pokemon.CON
	this.INT = this.raw_data.INT + pokemon.INT
	this.WIS = this.raw_data.WIS + pokemon.WIS
	this.CHA = this.raw_data.CHA + pokemon.CHA
	
	this.skills = this.raw_data.Skill or {}
	this.type = this.raw_data.Type
	this.resistance = this.raw_data.Res
	this.vulnerabilities = this.raw_data.Vul
	this.immunities = this.raw_data.Imm
	this.abilities = this.raw_data.Abilities
	this.HP = this.raw_data.HP
	this.proficiency = M.level_data(this.level).prof
	this.STAB = M.level_data(this.level).STAB
	
	
	add_score_from_nature(this)
	setup_saving_throws(this)
	setup_abilities(this)
	setup_moves(this)
	this.raw_data = nil
	return this
end

return M