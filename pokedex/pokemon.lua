local utils = require "utils.utils"
local pokedex = require "pokedex.pokedex"
local natures = require "pokedex.natures"
local storage = require "pokedex.storage"
local movedex = require "pokedex.moves"
local items = require "pokedex.items"
local trainer = require "pokedex.trainer"

local M = {}

local feat_to_skill = {
	Brawny="Athletics",
	Perceptive="Perception",
	Acrobat= "Acrobatics",
	["Quick-Fingered"]="Sleight of Hand",
	Stealthy="Stealth"
}
local resilient = {
	["Resilient (STR)"]= "STR",
	["Resilient (CON)"]= "CON",
	["Resilient (DEX)"]= "DEX",
	["Resilient (INT)"]= "INT",
	["Resilient (WIS)"]= "WIS",
	["Resilient (CHA)"]= "CHA",
}
local feat_to_attribute = {
	["Resilient (STR)"]= "STR",
	["Resilient (CON)"]= "CON",
	["Resilient (DEX)"]= "DEX",
	["Resilient (INT)"]= "INT",
	["Resilient (WIS)"]= "WIS",
	["Resilient (CHA)"]= "CHA",
	["Athlete (STR)"]= "STR",
	["Athlete (DEX)"]="DEX",
	["Quick-Fingered"]= "DEX",
	Stealthy="DEX",
	Brawny="STR",
	Perceptive="WIS",
	Acrobat="DEX"
}

M.GENDERLESS = pokedex.GENDERLESS
M.MALE = pokedex.MALE
M.FEMALE = pokedex.FEMALE

local loyalty_hp = {
	[-3] = {HP=0},
	[-2] = {HP=0},
	[-1] = {HP=0},
	[0] = {HP=0},
	[1] = {HP=0},
	[2] = {HP=5},
	[3] = {HP=10}
}

local function add_tables(T1, T2)
	local copy = utils.shallow_copy(T1)
	for k,v in pairs(T2) do
		if copy[k] then
			copy[k] = copy[k] + v
		end
	end
	return copy
end

function M.get_senses(pokemon)
	return pokedex.get_senses(M.get_current_species(pokemon))
end

local function get_attributes_from_feats(pokemon)
	local m = {STR=0, DEX=0, CON=0, INT=0, WIS=0, CHA=0}
	for _, feat in pairs(M.get_feats(pokemon)) do
		local attr = feat_to_attribute[feat]
		if attr then
			m[attr] = m[attr] + 1
		end
	end
	return m
end

--[[
A Bulbasaur when gaining ASI would get 2 points. If the Bulbasaur eats an Eviolite he gets 4 instead.
A Ivysaur when gaining ASI would get 2 points. If the Ivysaur eats an Eviolite he gets 3 instead.
A Venusaur when gaining ASI would get 2 points. Eating Eviolite have no effect
A Rattata when gaining ASI would get 3 points. If the Rattata eats an Eviolite he gets 4 points.
A RAticate when gaining ASI would get 3 points. Eating Eviolite have no effect
A Kangaskhan when gaining ASI would get 4 points.  Eating Eviolite have no effect--]]
local function ASI_points(pokemon)
	local species = M.get_current_species(pokemon)
	local total = pokedex.get_total_evolution_stages(species)
	local current = pokedex.get_current_evolution_stage(species)
	if M.get_consumed_eviolite(pokemon) then
		return 5 - current
	else
		return 5 - total
	end
end

function M.get_available_ASI(pokemon)
	local available_at_level = pokedex.level_data(M.get_current_level(pokemon)).ASI
	local available_at_caught = pokedex.level_data(M.get_caught_level(pokemon)).ASI
	local ASI_gained = M.get_ASI_point_increase(pokemon)
	return (available_at_level-available_at_caught) * ASI_gained - M.ability_score_points(pokemon) + trainer.get_asi()
end


function M.genderized(pokemon)
	local species = M.get_current_species(pokemon)
	return pokedex.genderized(species)
end

function M.get_gender(pokemon)
	return pokemon.gender
end

function M.set_gender(pokemon, gender)
	pokemon.gender = gender
end

function M.get_ASI_point_increase(pokemon)
	return ASI_points(pokemon)
end

function M.get_attributes(pokemon)
	local base = pokedex.get_base_attributes(M.get_caught_species(pokemon))
	local increased = M.get_increased_attributes(pokemon) or {}
	local added = M.get_added_attributes(pokemon) or {}
	local natures = natures.get_nature_attributes(M.get_nature(pokemon)) or {}
	local feats = get_attributes_from_feats(pokemon)
	local trainer_attributes = trainer.get_attributes()
	return add_tables(add_tables(add_tables(add_tables(add_tables(base, added), natures), increased), feats), trainer_attributes)
end

function M.get_max_attributes(pokemon)
	local m = {STR= 20,DEX= 20,CON= 20,INT= 20,WIS= 20,CHA= 20}
	local n = natures.get_nature_attributes(M.get_nature(pokemon)) or {}

	local t = add_tables(m, n)
	return t
end

function M.get_increased_attributes(pokemon)
	return pokemon.attributes.increased
end

function M.get_experience_for_level(pokemon)
	return pokedex.get_experience_for_level(M.get_current_level(pokemon))
end

function M.set_loyalty(pokemon, loyalty)
	local c =  math.min(math.max(loyalty, -3), 3)
	pokemon.loyalty = c
end

function M.get_held_item(pokemon)
	return pokemon.item
end

function M.set_held_item(pokemon, item)
	pokemon.item = item
end

function M.remove_feat(pokemon, feat)
	for i, name in pairs(M.get_feats(pokemon)) do
		if name == feat then
			if name == "Extra Move" then
				M.remove_move(pokemon, M.get_moves_count(pokemon))
				table.remove(pokemon.feats, i)
				break
			end
			table.remove(pokemon.feats, i)
		end
	end
end

function M.set_consumed_eviolite(pokemon, value)
	pokemon.eviolite = value == true and true or nil
end

function M.get_consumed_eviolite(pokemon, value)
	return pokemon.eviolite or false
end

function M.remove_move(pokemon, index)
	for move, data in pairs(M.get_moves(pokemon)) do
		if index == data.index then
			pokemon.moves[move] = nil
			break
		end
	end
end

function M.reset_abilities(pokemon)
	for i, name in pairs(M.get_abilities(pokemon)) do
		table.remove(pokemon.abilities, i)
	end
	for i, name in pairs(pokedex.get_pokemon_abilities(M.get_current_species(pokemon))) do
		table.insert(pokemon.abilities, name)
	end
end

function M.remove_ability(pokemon, ability)
	for i, name in pairs(M.get_abilities(pokemon)) do
		if name == ability then
			table.remove(pokemon.abilities, i)
		end
	end
end

function M.get_moves_count(pokemon)
	local c = 0
	for move, data in pairs(M.get_moves(pokemon)) do
		c = c + 1
	end
	return c
end

function M.set_nature(pokemon, nature)
	pokemon.nature = nature
	pokemon.attributes.nature = natures.get_nature_attributes(nature)
end

function M.get_loyalty(pokemon)
	return pokemon.loyalty or 0
end

function M.have_ability(pokemon, ability)
	local count = 0
	for _, f in pairs(M.get_abilities(pokemon)) do
		if f == ability then
			return true
		end
	end
	return false
end

function M.have_feat(pokemon, feat)
	local count = 0
	for _, f in pairs(M.get_feats(pokemon)) do
		if f == feat then
			count = count + 1
		end
	end
	return count > 0, count
end

function M.get_exp(pokemon)
	return pokemon.exp or 0
end

function M.set_exp(pokemon, exp)
	pokemon.exp = exp
end

function M.update_increased_attributes(pokemon, increased)
	local b = M.get_increased_attributes(pokemon)
	local n = add_tables(increased, b)
	pokemon.attributes.increased = n
end

function M.ability_score_points(pokemon)
	local amount = 0
	for _, n in pairs(M.get_increased_attributes(pokemon)) do
		amount = amount + n
	end
	amount = amount + #M.get_feats(pokemon) * 2
	amount = amount - M.get_evolution_points(pokemon)
	
	return amount
end

function M.get_added_attributes(pokemon)
	return {
		STR=pokemon.attributes["STR"] or 0,
		DEX=pokemon.attributes["DEX"] or 0,
		CON=pokemon.attributes["CON"] or 0,
		INT=pokemon.attributes["INT"] or 0,
		WIS=pokemon.attributes["WIS"] or 0,
		CHA=pokemon.attributes["CHA"] or 0
	}

end

function M.set_shiny(pokemon, value)
	pokemon.shiny = value == true and true or nil
end

function M.is_shiny(pokemon)
	return pokemon.shiny
end

function M.set_attribute(pokemon, attribute, value)
	pokemon.attributes[attribute] = value
end

function M.set_increased_attribute(pokemon, attribute, value)
	pokemon.attributes.increased[attribute] = value
end

function M.save(pokemon)
	return storage.update_pokemon(pokemon)
end

function M.get_speed_of_type(pokemon)
	local species = M.get_current_species(pokemon)
	local type = pokedex.get_pokemon_type(species)[1]
	local mobile_feet = 0
	if M.have_feat(pokemon, "Mobile") then
		mobile_feet = 10
	end
	if type == "Flying" then
		local speed = pokedex.get_flying_speed(species) 
		return speed ~= 0 and speed+mobile_feet or speed, "Flying"
	elseif type == "Water" then
		local speed = pokedex.get_swimming_speed(species) 
		return speed ~= 0 and speed+mobile_feet or speed, "Swimming"
	else
		local speed = pokedex.get_walking_speed(species) 
		return speed ~= 0 and speed+mobile_feet or speed, "Walking"
	end
end

function M.get_status_effects(pokemon)
	return pokemon.statuses or {}
end

function M.get_all_speed(pokemon)
	local species = M.get_current_species(pokemon)
	local mobile_feet = 0
	if M.have_feat(pokemon, "Mobile") then
		mobile_feet = 10
	end
	local w = pokedex.get_walking_speed(species) 
	local s = pokedex.get_swimming_speed(species) 
	local c = pokedex.get_climbing_speed(species) 
	local f = pokedex.get_flying_speed(species) 
	return {Walking= w ~= 0 and w+mobile_feet or w, Swimming=s ~= 0 and s+mobile_feet or s, 
	Flying= f ~= 0 and f+mobile_feet or f, Climbing=c ~= 0 and c+mobile_feet or c}
end

function M.set_current_hp(pokemon, hp)
	pokemon.hp.current = hp
end

function M.get_current_hp(pokemon)
	return pokemon.hp.current
end

function M.set_max_hp(pokemon, hp)
	pokemon.hp.max = hp
end

function M.set_max_hp_forced(pokemon, forced)
	pokemon.hp.edited = forced
end

function M.get_max_hp_forced(pokemon)
	return pokemon.hp.edited
end


function M.get_max_hp(pokemon)
	return pokemon.hp.max
end

function M.get_defaut_max_hp(pokemon)
	if M.have_ability(pokemon, "Paper Thin") then
		return 1
	end
	local current = M.get_current_species(pokemon)
	local caught = M.get_caught_species(pokemon)
	local at_level = M.get_current_level(pokemon)
	
	if current ~= caught then
		local evolutions = utils.shallow_copy(M.get_evolution_level(pokemon))
		local evolution_hp = 0

		while next(evolutions) ~= nil do
			local from_pokemon = pokedex.get_evolved_from(current)
			at_level = table.remove(evolutions)
			local _, from_level = next(evolutions)
			from_level = from_level or M.get_caught_level(pokemon)
			local hit_dice = pokedex.get_pokemon_hit_dice(from_pokemon)
			local hit_dice_current = pokedex.get_pokemon_hit_dice(current)
			local levels_gained = at_level - from_level
			local hp_hit_dice = math.ceil((hit_dice + 1) / 2) * levels_gained
			local hp_evo = at_level * 2
			-- Offset of current hit dice and the new one
			local hp_offset = math.ceil((hit_dice_current + 1) / 2) - math.ceil((hit_dice + 1) / 2)
			evolution_hp = evolution_hp + hp_hit_dice + hp_evo + hp_offset
			current = from_pokemon
		end

		evolutions = M.get_evolution_level(pokemon)
		local hit_dice = pokedex.get_pokemon_hit_dice(M.get_current_species(pokemon))
		local hit_dice_avg = math.ceil((hit_dice + 1) / 2)
		return pokedex.get_base_hp(caught) + evolution_hp + ((M.get_current_level(pokemon) - evolutions[#evolutions]) * hit_dice_avg)
	else
		local base = pokedex.get_base_hp(current)
		local from_level = M.get_caught_level(pokemon)
		local hit_dice = pokedex.get_pokemon_hit_dice(current)
		local levels_gained = at_level - from_level
		local hp_hit_dice = math.ceil((hit_dice + 1) / 2) * levels_gained
		return base + hp_hit_dice
	end
end


function M.get_evolution_points(pokemon)
	local current = M.get_current_species(pokemon)
	local caught = M.get_caught_species(pokemon)
	local evolution_points = 0
	
	if current ~= caught then
		local evolutions = utils.deep_copy(M.get_evolution_level(pokemon))

		while next(evolutions) ~= nil do
			table.remove(evolutions)
			current = pokedex.get_evolved_from(current)
			evolution_points = evolution_points + pokedex.evolve_points(current)
		end
	end
	return evolution_points
end

function M.get_total_max_hp(pokemon)
	if M.have_ability(pokemon, "Paper Thin") then
		return 1
	end
	
	local tough_feat = 0
	if M.have_feat(pokemon, "Tough") then
		tough_feat = M.get_current_level(pokemon) * 2
	end
	
	local con = M.get_attributes(pokemon).CON
	local con_mod = math.floor((con - 10) / 2)

	return M.get_max_hp(pokemon) + tough_feat + loyalty_hp[M.get_loyalty(pokemon)].HP + M.get_current_level(pokemon) * con_mod
end

function M.get_current_species(pokemon)
	return pokemon.species.current
end

local function set_species(pokemon, species)
	pokemon.species.current = species
end

function M.get_caught_species(pokemon)
	return pokemon.species.caught
end

function M.get_current_level(pokemon)
	return pokemon.level.current
end

function M.get_caught_level(pokemon)
	return pokemon.level.caught
end

function M.set_move(pokemon, new_move, index)
	local pp = movedex.get_move_pp(new_move)
	for name, move in pairs(M.get_moves(pokemon)) do
		if move.index == index then
			pokemon.moves[name] = nil
			pokemon.moves[new_move] = {pp=pp, index=index}
			return
		end
	end
	pokemon.moves[new_move] = {pp=pp, index=index}
end

function M.get_moves(pokemon)
	return pokemon.moves
end

function M.get_nature(pokemon)
	return pokemon.nature
end

function M.get_id(pokemon)
	return pokemon.id
end

function M.get_type(pokemon)
	return pokedex.get_pokemon_type(M.get_current_species(pokemon))
end

function M.get_STAB_bonus(pokemon)
	return pokedex.level_data(M.get_current_level(pokemon)).STAB
end

function M.get_proficency_bonus(pokemon)
	return pokedex.level_data(M.get_current_level(pokemon)).prof
end

function M.update_abilities(pokemon, abilities)
	pokemon.abilities = abilities
end

function M.update_feats(pokemon, feats)
	pokemon.feats = feats
end

function M.get_feats(pokemon)
	return pokemon.feats or {}
end


function M.add_feat(pokemon, feat)
	table.insert(pokemon.feats, feat)
end

function M.add_ability(pokemon, ability)
	table.insert(pokemon.abilities, ability)
end

function M.get_abilities(pokemon, as_raw)
	local species = M.get_current_species(pokemon)
	local t = {}
	t = pokemon.abilities or pokedex.get_pokemon_abilities(species) or {}
	if not as_raw and M.have_feat(pokemon, "Hidden Ability") then
		local hidden = pokedex.get_pokemon_hidden_ability(species)
		local added = false
		for _, h in pairs(t) do
			if h == hidden then
				added = true
			end
		end
		if not added then
			table.insert(t, hidden)
		end
	end
	return t
end

function M.get_skills(pokemon)
	local skills = pokedex.get_pokemon_skills(M.get_current_species(pokemon)) or {}
	for feat, skill in pairs(feat_to_skill) do
		local added = false
		if M.have_feat(pokemon, feat) then
			for i=#skills, -1, -1 do
				if skill == skills[i] then
					table.remove(skills, i)
					table.insert(skills, skill .. " (e)")
					added = true
				end
			end
			if not added then
				table.insert(skills, skill)
			end
		end
	end

	return skills
end

function M.get_move_pp(pokemon, move)
	-- If the move somehow became nil (which can happen in corrupted data cases due to issue https://github.com/Jerakin/Pokedex5E/issues/407),
	-- reset it to the move's base pp to avoid exceptions in other places. Ideally the corruption would never happen in the first place, but
	-- some save data is already corrupt.
	local pp = pokemon.moves[move].pp
	if pp == nil then
		M.reset_move_pp(pokemon, move)
		pp = pokemon.moves[move].pp
	end
	return pp
end

function M.get_move_pp_max(pokemon, move)
	local _, pp_extra = M.have_feat(pokemon, "Tireless")
	local move_pp = movedex.get_move_pp(move)
	if type(move_pp) == "string" then
		-- probably move with Unlimited uses, i.e. Struggle
		return move_pp
	end
	return movedex.get_move_pp(move) + pp_extra
end

function M.get_move_index(pokemon, move)
	return pokemon.moves[move].index
end

function M.reset(pokemon)
	M.set_current_hp(pokemon, M.get_total_max_hp(pokemon))
	for name, move in pairs(M.get_moves(pokemon)) do
		M.reset_move_pp(pokemon, name)
	end
	pokemon.statuses = {}
end

function M.reset_in_storage(pokemon)
	M.reset(pokemon)
	storage.update_pokemon(pokemon)
end

function M.get_vulnerabilities(pokemon)
	return pokedex.get_pokemon_vulnerabilities(M.get_current_species(pokemon))
end

function M.get_immunities(pokemon)
	return pokedex.get_pokemon_immunities(M.get_current_species(pokemon))
end

function M.get_resistances(pokemon)
	return pokedex.get_pokemon_resistances(M.get_current_species(pokemon))
end

function M.decrease_move_pp(pokemon, move)
	local move_pp = M.get_move_pp(pokemon, move)
	if type(move_pp) == "string" then
		return
	end
	local pp = math.max(move_pp - 1, 0)
	pokemon.moves[move].pp = pp
	return pp
end

function M.increase_move_pp(pokemon, move)
	local move_pp = M.get_move_pp(pokemon, move)
	if type(move_pp) == "string" then
		return
	end
	local max_pp = M.get_move_pp_max(pokemon, move)
	local pp = math.min(move_pp + 1, max_pp)
	pokemon.moves[move].pp = pp
	return pp
end


function M.reset_move_pp(pokemon, move)
	local pp = M.get_move_pp_max(pokemon, move)
	pokemon.moves[move].pp = pp
end

local function set_evolution_at_level(pokemon, level)
	if type(pokemon.level.evolved) == "number" then
		local old = pokemon.level.evolved
		pokemon.level.evolved = {}
		if old ~= 0 then
			table.insert(pokemon.level.evolved, old)
		end
	end
	
	table.insert(pokemon.level.evolved, level)
end

function M.calculate_addition_hp_from_levels(pokemon, levels_gained)
	local hit_dice = M.get_hit_dice(pokemon)
	local con = M.get_attributes(pokemon).CON
	local con_mod = math.floor((con - 10) / 2)

	local from_hit_dice = math.ceil((hit_dice + 1) / 2) * levels_gained
	local from_con_mod = con_mod * levels_gained
	return from_hit_dice + from_con_mod
end

function M.set_current_level(pokemon, level)
	pokemon.level.current = level
end

function M.add_hp_from_levels(pokemon, from_level)
	if not M.get_max_hp_forced(pokemon) and not M.have_ability(pokemon, "Paper Thin") then
		local hit_dice = M.get_hit_dice(pokemon)
		
		local from_hit_dice = math.ceil((hit_dice + 1) / 2) *  M.get_current_level(pokemon) - from_level
		
		local max = M.get_max_hp(pokemon)
		M.set_max_hp(pokemon, max + from_hit_dice)
		
		-- Also increase current hp
		local c = M.get_current_hp(pokemon)
		M.set_current_hp(pokemon, c + from_hit_dice)
	end
end

function M.evolve(pokemon, to_species)
	local level = M.get_current_level(pokemon)
	if not M.get_max_hp_forced(pokemon) then
		local current = M.get_max_hp(pokemon)
		local gained = level * 2
		M.set_max_hp(pokemon, current + gained)
		
		-- Also increase current hp
		local c = M.get_current_hp(pokemon)
		M.set_current_hp(pokemon, c + gained)
	end
	set_evolution_at_level(pokemon, level)
	set_species(pokemon, to_species)
end


function M.get_saving_throw_modifier(pokemon)
	local prof = M.get_proficency_bonus(pokemon)
	local b = M.get_attributes(pokemon)
	local saving_throws = pokedex.get_saving_throw_proficiencies(M.get_current_species(pokemon)) or {}
	local loyalty = M.get_loyalty(pokemon)
	for _, feat in pairs(M.get_feats(pokemon)) do
		local is_resilient = resilient[feat]
		local got_save = false
		if is_resilient then
			for _, save in pairs(saving_throws) do
				if save == is_resilient then
					got_save = true
				end
			end
			if not got_save then
				table.insert(saving_throws, is_resilient)
			end
		end
	end
	
	local modifiers = {}
	for name, mod in pairs(b) do
		modifiers[name] = math.floor((b[name] - 10) / 2) + loyalty
	end
	for _, st in pairs(saving_throws) do
		modifiers[st] = modifiers[st] + prof
	end

	return modifiers
end

function M.set_nickname(pokemon, nickname)
	local species = M.get_current_species(pokemon)
	if nickname and species:lower() ~= nickname:lower() then
		pokemon.nickname = nickname
	else
		pokemon.nickname = nil
	end
end

function M.get_nickname(pokemon)
	return storage.get_nickname(M.get_id(pokemon))
end

function M.get_AC(pokemon)
	local _, AC_UP = M.have_feat(pokemon, "AC Up")
	return pokedex.get_pokemon_AC(M.get_current_species(pokemon)) + natures.get_AC(M.get_nature(pokemon)) + AC_UP
end

function M.get_index_number(pokemon)
	return pokedex.get_index_number(M.get_current_species(pokemon))
end

function M.get_hit_dice(pokemon)
	return pokedex.get_pokemon_hit_dice(M.get_current_species(pokemon))
end

function M.get_pokemon_exp_worth(pokemon)
	local level = M.get_current_level(pokemon)
	local sr = pokedex.get_pokemon_SR(M.get_current_species(pokemon))
	return pokedex.get_pokemon_exp_worth(level, sr)
end

function M.get_catch_rate(pokemon)
	local l = M.get_current_level(pokemon)
	local sr = math.floor(pokedex.get_pokemon_SR(M.get_current_species(pokemon)))
	local hp = math.floor(M.get_current_hp(pokemon) / 10)
	return 10 + l + sr + hp
end

function M.get_evolution_level(pokemon)
	if type(pokemon.level.evolved) == "number" then
		local old = pokemon.level.evolved
		pokemon.level.evolved = {}
		if old ~= 0 then
			table.insert(pokemon.level.evolved, old)
		end
	end
	return pokemon.level.evolved or {}
end

function M.get_icon(pokemon)
	local species = M.get_current_species(pokemon)
	return pokedex.get_icon(species)
end

function M.get_sprite(pokemon)
	local species = M.get_current_species(pokemon)
	return pokedex.get_sprite(species)
end

local function level_index(level)
	if level >= 17 then
		return "17"
	elseif level >= 10 then
		return "10"
	elseif level >= 5 then
		return "5"
	else
		return "1"
	end
end

local function get_damage_mod_stab(pokemon, move)
	local modifier
	local damage
	local ab
	local stab = false
	local stab_damage = 0
	local total = M.get_total_attribute
	local floored_mod
	local trainer_stab = 0
	-- Pick the highest of the moves power
	local total = M.get_attributes(pokemon)
	if move["Move Power"] then
		for _, mod in pairs(move["Move Power"]) do
			if total[mod] then
				local floored_mod = math.floor((total[mod] - 10) / 2)
				if modifier then
					if floored_mod > modifier then
						modifier = floored_mod
					end
				else
					modifier = floored_mod
				end
			elseif mod == "Any" then
				print("ANY!")
				local max = 0
				for k, v in pairs(total) do
					max = math.max(v, max)
				end
				modifier = math.floor((max - 10) / 2)
			end
		end
	end
	
	modifier = modifier ~= nil and modifier or 0

	for _, t in pairs(M.get_type(pokemon)) do
		trainer_stab = trainer_stab + trainer.get_type_master_STAB(t)
		if move.Type == t and move.stab then
			stab_damage = M.get_STAB_bonus(pokemon) + trainer.get_all_levels_STAB() + trainer.get_STAB(t)
			stab = true
		end
	end
	if stab then
		stab_damage = stab_damage + trainer_stab
	end
	
	local index = level_index(M.get_current_level(pokemon))
	
	local move_damage = move.Damage
	if move_damage then
		local times_prefix = ""
		if move_damage[index].times then
			times_prefix = move_damage[index].times .. "x"
		end

		damage = times_prefix .. move_damage[index].amount .. "d" .. move_damage[index].dice_max
		local extra = stab_damage + (move_damage[index].modifier or 0) + (move_damage[index].level and M.get_current_level(pokemon) or 0) + trainer.get_damage()
		if move_damage[index].move then
			extra = extra + modifier + trainer.get_move()
		end

		if extra ~= 0 then
			local symbol = ""
			if extra > 0 then
				symbol = "+"
			end
			damage = damage .. symbol .. extra
		end
	end
	return damage, modifier, stab
end	

function M.get_move_data(pokemon, move_name)
	local move = movedex.get_move_data(move_name)
	local dmg, mod, stab = get_damage_mod_stab(pokemon, move)
	
	local move_data = {}
	move_data.damage = dmg
	move_data.stab = stab
	move_data.name = move_name
	move_data.type = move.Type
	move_data.PP = move.PP
	move_data.duration = move.Duration
	move_data.range = move.Range
	move_data.description = move.Description
	move_data.power = move["Move Power"]
	move_data.save = move.Save
	move_data.time = move["Move Time"]
	if move.ab then
		move_data.AB = mod + M.get_proficency_bonus(pokemon) + trainer.get_attack_roll() + trainer.get_move_type_attack_bonus(move_data.type) + trainer.get_pokemon_type_attack_bonus(M.get_type(pokemon))
	end
	if move_data.save then
		move_data.save_dc = 8 + mod + M.get_proficency_bonus(pokemon)
	end

	return move_data
end



local function get_starting_moves(pokemon, number_of_moves)
	-- We get all moves
	local number_of_moves = number_of_moves or 4
	local starting_moves = pokedex.get_starting_moves(M.get_current_species(pokemon))

	-- Shuffle the moves around, we want random moves
	if #starting_moves > number_of_moves then
		starting_moves = utils.shuffle2(starting_moves)
	end

	-- Setup moves
	local moves = {}
	for i=1, number_of_moves do
		if starting_moves[i] then
			local pp = movedex.get_move_pp(starting_moves[i])
			moves[starting_moves[i]] = {pp=pp, index=i}
		end
	end
	return moves
end

function M.new(data)
	local this = {}
	this.species = {}
	this.species.caught = data.species
	this.species.current = data.species

	this.level = {}
	this.level.caught = pokedex.get_minimum_wild_level(this.species.caught)
	this.level.current = this.level.caught
	this.level.evolved = {}

	this.attributes = {STR=0, DEX=0, CON=0, INT=0, WIS=0, CHA=0}
	this.attributes.increased = {STR=0, DEX=0, CON=0, INT=0, WIS=0, CHA=0}

	this.nature = "No Nature"

	this.feats = {}
	this.abilities = pokedex.get_pokemon_abilities(data.species)

	this.exp = pokedex.get_experience_for_level(this.level.caught-1)

	this.loyalty = 0
	
	local con = M.get_attributes(this).CON
	local con_mod = math.floor((con - 10) / 2)

	this.hp = {}
	this.hp.max = pokedex.get_base_hp(data.species)
	this.hp.current = pokedex.get_base_hp(data.species) + this.level.current * math.floor((M.get_attributes(this).CON - 10) / 2)
	this.hp.edited = false

	this.moves = get_starting_moves(this, data.number_of_moves)
	
	return this
end



return M