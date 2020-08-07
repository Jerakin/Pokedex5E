local profiles = require "pokedex.profiles"
local defsave = require "defsave.defsave"
local utils = require "utils.utils"
local M = {}

local trainer

local _trainer = {ab=0, dmg=0, evo=0, all_stab=0, asi=0, move=0,
	tm_stab ={Normal=0, Fire=0, Water=0, Electric=0, Grass=0, Ice=0, Fighting=0, Poison=0, Ground=0, Flying=0, Psychic=0, Bug=0, Rock=0, Ghost=0, Dragon=0, Dark=0, Steel=0, Fairy=0},
	stab    = {Normal=0, Fire=0, Water=0, Electric=0, Grass=0, Ice=0, Fighting=0, Poison=0, Ground=0, Flying=0, Psychic=0, Bug=0, Rock=0, Ghost=0, Dragon=0, Dark=0, Steel=0, Fairy=0},
	move_type_ab = {Normal=0, Fire=0, Water=0, Electric=0, Grass=0, Ice=0, Fighting=0, Poison=0, Ground=0, Flying=0, Psychic=0, Bug=0, Rock=0, Ghost=0, Dragon=0, Dark=0, Steel=0, Fairy=0},
	pokemon_type_ab = {Normal=0, Fire=0, Water=0, Electric=0, Grass=0, Ice=0, Fighting=0, Poison=0, Ground=0, Flying=0, Psychic=0, Bug=0, Rock=0, Ghost=0, Dragon=0, Dark=0, Steel=0, Fairy=0},
	move_type_damage = {Normal=0, Fire=0, Water=0, Electric=0, Grass=0, Ice=0, Fighting=0, Poison=0, Ground=0, Flying=0, Psychic=0, Bug=0, Rock=0, Ghost=0, Dragon=0, Dark=0, Steel=0, Fairy=0},
	pokemon_type_damage = {Normal=0, Fire=0, Water=0, Electric=0, Grass=0, Ice=0, Fighting=0, Poison=0, Ground=0, Flying=0, Psychic=0, Bug=0, Rock=0, Ghost=0, Dragon=0, Dark=0, Steel=0, Fairy=0},
	always_use_STAB = {Normal=false, Fire=false, Water=false, Electric=false, Grass=false, Ice=false, Fighting=false, Poison=false, Ground=false, Flying=false, Psychic=false, Bug=false, Rock=false, Ghost=false, Dragon=false, Dark=false, Steel=false, Fairy=false},
	attributes = {STR=0, DEX=0, CON=0, WIS=0, INT=0, CHA=0}
}

function M.get_asi()
	return trainer.asi
end

function M.get_move()
	return trainer.move
end

function M.get_attack_roll()
	return trainer.ab
end

function M.get_damage()
	return trainer.dmg
end

function M.get_evolution_level()
	return trainer.evo
end

function M.get_all_levels_STAB()
	return trainer.all_stab
end

function M.get_type_master_STAB(_type)
	return trainer.tm_stab[_type] or 0
end

function M.get_STAB(_type)
	return trainer.stab[_type] or 0
end

function M.get_attribute(attribute)
	return trainer.attributes[attribute] or 0
end

function M.get_attributes()
	return trainer.attributes
end

function M.get_move_type_attack_bonus(_type)
	if trainer.move_type_ab[_type] ~= nil then
		return trainer.move_type_ab[_type]
	end
	return 0
end

function M.get_pokemon_type_attack_bonus(_types)
	local num
	for _, t in pairs(_types) do
		local ab = trainer.pokemon_type_ab[t]
		if ab ~= nil then
			if num == nil then
				num = ab
			else
				num = math.max(num, ab)
			end
		end
	end
	return num or 0
end

function M.get_pokemon_type_attack_bonus_single(_type)
	return trainer.pokemon_type_ab[_type] or 0
end

function M.get_type_attack_bonus(_type)
	if trainer.type_ab[_type] ~= nil then
		return trainer.type_ab[_type]
	end
	return 0
end

function M.get_always_use_STAB(_type)
	return trainer.always_use_STAB[_type]
end

function M.set_move(value)
	trainer.move = value
end


function M.set_asi(value)
	trainer.asi = value
end

function M.set_attack_roll(value)
	trainer.ab = value
end

function M.set_damage(value)
	trainer.dmg = value
end

function M.set_evolution_level(value)
	trainer.evo = value
end

function M.set_all_levels_STAB(value)
	trainer.all_stab = value
end

function M.set_type_master_STAB(_type, value)
	trainer.tm_stab[_type] = value
end

function M.set_STAB(_type, value)
	trainer.stab[_type] = value
end

function M.set_attribute(attribute, value)
	trainer.attributes[attribute] = value
end

function M.set_move_type_attack_bonus(_type, value)
	trainer.move_type_ab[_type] = value
end

function M.set_pokemon_type_attack_bonus(_type, value)
	trainer.pokemon_type_ab[_type] = value
end


function M.set_always_use_STAB(_type, value)
	trainer.always_use_STAB[_type] = value
end


function M.get_pokemon_type_damage_bonus(_type)
	return trainer.pokemon_type_damage[_type]
end
function M.set_pokemon_type_damage_bonus(_type, value)
	trainer.pokemon_type_damage[_type] = value
end
function M.get_move_type_damage_bonus(_type)
	return trainer.move_type_damage[_type] or 0
end
function M.set_move_type_damage_bonus(_type, value)
	trainer.move_type_damage[_type] = value
end

function M.test()
	trainer = (trainer == nil or next(trainer) == nil) and utils.deep_copy(_trainer) or trainer
end

function M.reset()
	trainer = utils.deep_copy(_trainer)
end

function M.load(_profile)
	local profile = _profile
	local file_name
	if profile == nil then
		file_name = profiles.get_active_file_name()
	else
		file_name = _profile.file_name
	end
	if file_name == nil then
		return
	end
	if not defsave.is_loaded(file_name) then
		local loaded = defsave.load(file_name)
	end
	trainer = defsave.get(file_name, "trainer")
	trainer = next(trainer) == nil and utils.deep_copy(_trainer) or trainer

	for key, value in pairs(_trainer) do
		if trainer[key] == nil then
			trainer[key] = utils.deep_copy(value)
		end
	end
end

function M.save()
	if profiles.get_active_slot() then
		local profile = profiles.get_active_file_name()
		defsave.set(profile, "trainer", trainer)
	end
end

return M