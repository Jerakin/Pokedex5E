local _pokemon = require "pokedex.pokemon"
local pokedex = require "pokedex.pokedex"
local party_utils = require "screens.party.utils"
local gooey = require "gooey.goeey"

local M = {}

local function setup_static_information(nodes, pokemon)
	local speed, stype = _pokemon.get_speed_of_type(pokemon)
	local nickname = _pokemon.get_nickname(pokemon)
	local species = _pokemon.get_current_species(pokemon)
	nickname = nickname or species:upper()

	local pokemon_sprite, texture = _pokemon.get_sprite(pokemon)
	gui.set_texture(nodes["pokemon/pokemon_sprite"], texture)
	gui.play_flipbook(nodes["pokemon/pokemon_sprite"], pokemon_sprite)

	gui.set_text(nodes["pokemon/txt_speed"], stype:upper() .. ": " .. speed)
	gui.set_text(nodes["pokemon/index"], string.format("#%03d %s", _pokemon.get_index_number(pokemon), species))
	gui.set_text(nodes["pokemon/species"], nickname)
	gui.set_text(nodes["pokemon/level"], "Lv. " ..  _pokemon.get_current_level(pokemon))
	gui.set_text(nodes["pokemon/nature"], _pokemon.get_nature(pokemon))
	gui.set_text(nodes["pokemon/ac"], "AC: " .. _pokemon.get_AC(pokemon))
	local vul = nodes["pokemon/vulnerabilities"]
	local imm = nodes["pokemon/immunities"]
	local res = nodes["pokemon/resistances"]
	gui.set_text(vul, party_utils.join_table("Vulnerabilities: ", _pokemon.get_vulnerabilities(pokemon), ", "))
	gui.set_text(res, party_utils.join_table("Resistances: ", _pokemon.get_resistances(pokemon), ", "))
	gui.set_text(imm, party_utils.join_table("Immunities: ", _pokemon.get_immunities(pokemon), ", "))
end

function M.update(nodes)
	local catch_rate = 10 + _pokemon.get_current_level(pokemon) + round_down(pokedex.get_pokemon_SR(pokemon)) + round_down(_pokemon.get_current_hp(pokemon) / 10)
	gui.set_text(nodes["pokemon/catch"], catch_rate)
end

local function round_up(num)
	if num<0 then x=-.55 else x=.5 end
	local int, _= math.modf(num+x)
	return int
end

local function round_down(num)
	if num<0 then x=-.4999 else x=.4999 end
	local int, _= math.modf(num+x)
	return int
end

local function setup_info_tab(nodes, pokemon)
	local abilities_string1 = ""
	local saving_throw_string1 = ""
	local abilities_string2 = ""
	local saving_throw_string2 = ""

	local st_attributes = _pokemon.get_saving_throw_modifier(pokemon)
	local total_attributes = _pokemon.get_attributes(pokemon)
	for i, stat in pairs({"STR", "DEX", "CON"}) do
		abilities_string1 = abilities_string1 .. total_attributes[stat] .. "\n"
		saving_throw_string1 = saving_throw_string1 .. party_utils.add_operation(st_attributes[stat])  .. "\n"
	end	

	for i, stat in pairs({"INT", "WIS", "CHA"}) do
		abilities_string2 = abilities_string2 .. total_attributes[stat] .. "\n"
		saving_throw_string2 = saving_throw_string2 .. party_utils.add_operation(st_attributes[stat])  .. "\n"
	end

	gui.set_text(nodes["pokemon/attributes_1"], abilities_string1)
	gui.set_text(nodes["pokemon/savingthrow_1"], saving_throw_string1)
	gui.set_text(nodes["pokemon/attributes_2"], abilities_string2)
	gui.set_text(nodes["pokemon/savingthrow_2"], saving_throw_string2)

	gui.set_text(nodes["pokemon/stab"], "STAB: " .. _pokemon.get_STAB_bonus(pokemon))
	gui.set_text(nodes["pokemon/prof"], "Prof: " .. _pokemon.get_proficency_bonus(pokemon))
	gui.set_text(nodes["pokemon/skills"], table.concat(_pokemon.get_skills(pokemon), ", "))

	gui.set_text(nodes["pokemon/type"], table.concat(_pokemon.get_type(pokemon), "/"))

	
	gui.set_text(nodes["pokemon/exp"], _pokemon.get_pokemon_exp_worth(pokemon))

	local catch_rate = 10 + _pokemon.get_current_level(pokemon) + round_down(pokedex.get_pokemon_SR(pokemon)) + round_down(_pokemon.get_current_hp(pokemon) / 10)
	gui.set_text(nodes["pokemon/catch"], catch_rate)
	
	local senses = _pokemon.get_senses(pokemon)
	if next(senses) ~= nil then
		gui.set_text(nodes["pokemon/txt_senses"], table.concat(_pokemon.get_senses(pokemon), "\n"))
	end
	local speeds = _pokemon.get_all_speed(pokemon)
	local speed_string = ""
	for name, amount in pairs(speeds) do
		if amount > 0 then
			speed_string = speed_string .. amount .. "ft. " .. name .. "\n"
		end
	end
	gui.set_text(nodes["pokemon/txt_speeds"], speed_string)
end

function M.on_input()
	gooey.static_list(list.id, list.stencil, list.data, action_id, action, function() end, function() end)
end

function M.create(nodes, pokemon)
	setup_static_information(nodes, pokemon)
	setup_info_tab(nodes, pokemon)
end


return M