local _pokemon = require "pokedex.pokemon"
local pokedex = require "pokedex.pokedex"
local storage = require "pokedex.storage"
local items = require "pokedex.items"
local party_utils = require "screens.party.utils"
local gooey = require "gooey.gooey"
local utils = require "utils.utils"
local gui_utils = require "utils.gui"
local gui_colors = require "utils.gui_colors"
local monarch = require "monarch.monarch"
local url = require "utils.url"
local scrollhandler = require "screens.party.components.scrollhandler"
local constants = require "utils.constants"
local screens = require "utils.screens"
local messages = require "utils.messages"

local M = {}
local active = {}
local touching = false
local _action = vmath.vector3(0)
local POKEMON_SPECIES_TEXT_SCALE = vmath.vector3(1.5)

local item_button
local rest_button
local active_pokemon


local function setup_main_information(nodes, pokemon)
	local speed, stype = _pokemon.get_speed_of_type(pokemon)
	local nickname = _pokemon.get_nickname(pokemon)
	local species = _pokemon.get_current_species(pokemon)
	nickname = nickname or species:upper()
	
	local pokemon_sprite, texture = _pokemon.get_sprite(pokemon)
	gui.set_texture(nodes["pokemon/pokemon_sprite"], texture)
	if pokemon_sprite then
		gui.play_flipbook(nodes["pokemon/pokemon_sprite"], pokemon_sprite)
	end

	gui.set_text(nodes["pokemon/index"], string.format("#%03d %s", _pokemon.get_index_number(pokemon), species))
	
	gui.set_text(nodes["pokemon/species"], nickname)
	gui.set_text(nodes["pokemon/level"], "Lv. " ..  _pokemon.get_current_level(pokemon))
	gui.set_text(nodes["pokemon/ac"], "AC: " .. _pokemon.get_AC(pokemon))
	local vul = nodes["pokemon/traits/vulnerabilities_list"]
	local imm = nodes["pokemon/traits/immunities_list"]
	local res = nodes["pokemon/traits/resistances_list"]
	gui.set_text(vul, party_utils.join_table("", _pokemon.get_vulnerabilities(pokemon), ", "))
	gui.set_text(res, party_utils.join_table("", _pokemon.get_resistances(pokemon), ", "))
	gui.set_text(imm, party_utils.join_table("", _pokemon.get_immunities(pokemon), ", "))

	gui.set_scale(vul, vmath.vector3(1))
	gui.set_scale(res, vmath.vector3(1))
	gui.set_scale(imm, vmath.vector3(1))
	
	gui_utils.scale_text_to_fit_size(vul)
	gui_utils.scale_text_to_fit_size(res)
	gui_utils.scale_text_to_fit_size(imm)
	
	gui.set_scale(nodes["pokemon/species"], POKEMON_SPECIES_TEXT_SCALE)
	gui_utils.scale_text_to_fit_size(nodes["pokemon/species"])
end


function M.refresh(pokemon_id)
	local pokemon = storage.get_copy(pokemon_id)
	gui.set_text(active["pokemon/traits/txt_catch"], _pokemon.get_catch_rate(pokemon))
	local st_attributes = _pokemon.get_saving_throw_modifier(pokemon)
	for i, stat in pairs(constants.ABILITY_LIST) do
		local save_node = "pokemon/txt_" .. stat:lower() .. "_save"
		gui.set_text(active[save_node], party_utils.add_operation(st_attributes[stat]))
	end	
end


local function setup_info_tab(nodes, pokemon)
	local abilities_string1 = ""
	local saving_throw_string1 = ""
	local abilities_string2 = ""
	local saving_throw_string2 = ""

	local st_attributes = _pokemon.get_saving_throw_modifier(pokemon)
	local total_attributes = _pokemon.get_attributes(pokemon)
	for i, stat in pairs(constants.ABILITY_LIST) do
		local mod_node = "pokemon/txt_" .. stat:lower() .. "_mod"
		local score_node = "pokemon/txt_" .. stat:lower() .. "_score"
		local save_node = "pokemon/txt_" .. stat:lower() .. "_save"

		gui.set_text(nodes[mod_node], party_utils.to_mod(total_attributes[stat]))
		gui.set_text(nodes[save_node], party_utils.add_operation(st_attributes[stat]))
		gui.set_text(nodes[score_node], total_attributes[stat])
	end	

	local skill_string = ""
	for _, skill in pairs(_pokemon.get_skills(pokemon)) do
		skill_string = skill_string .. "• " .. skill .. "\n"
	end
	gui.set_text(nodes["pokemon/traits/txt_skills"], skill_string)

	local sr = pokedex.get_pokemon_SR(_pokemon.get_current_species(pokemon))
	gui.set_text(nodes["pokemon/traits/txt_sr"], constants.NUMBER_TO_SR[sr])

	gui.set_text(nodes["pokemon/traits/txt_size"], _pokemon.get_size(pokemon):upper())
	gui.set_text(nodes["pokemon/traits/txt_nature"], _pokemon.get_nature(pokemon):upper())
	gui.set_text(nodes["pokemon/traits/txt_stab"], _pokemon.get_STAB_bonus(pokemon))
	gui.set_text(nodes["pokemon/traits/txt_prof"], _pokemon.get_proficency_bonus(pokemon))
	gui.set_text(nodes["pokemon/traits/txt_exp"], _pokemon.get_pokemon_exp_worth(pokemon))
	gui.set_text(nodes["pokemon/traits/txt_catch"], _pokemon.get_catch_rate(pokemon))
	gui.set_text(nodes["pokemon/traits/txt_hitdice"], "d" .. _pokemon.get_hit_dice(pokemon))

	local pokemon_types = _pokemon.get_type(pokemon)

	if #pokemon_types == 1 then
		gui.set_enabled(nodes["pokemon/traits/type_1"], false)
		gui.set_enabled(nodes["pokemon/traits/type_2"], false)
		gui.set_enabled(nodes["pokemon/traits/type_3"], true)
		gui.play_flipbook(nodes["pokemon/traits/type_3"], pokemon_types[1]:lower())
	else
		gui.set_enabled(nodes["pokemon/traits/type_1"], true)
		gui.set_enabled(nodes["pokemon/traits/type_2"], true)
		gui.set_enabled(nodes["pokemon/traits/type_3"], false)
		gui.play_flipbook(nodes["pokemon/traits/type_1"], pokemon_types[1]:lower())
		gui.play_flipbook(nodes["pokemon/traits/type_2"], pokemon_types[2]:lower())
	end
	
	local item = _pokemon.get_held_item(pokemon)
	if item then
		item_button = party_utils.set_id(nodes["pokemon/held_item"])
		gui.set_text(nodes["pokemon/txt_held_item"], item:upper())
	else
		gui.set_text(nodes["pokemon/txt_held_item"], "ITEM: NONE")
	end

	for name, amount in pairs(_pokemon.get_all_speed(pokemon)) do
		gui.set_text(nodes["pokemon/traits/txt_" .. name:lower()], amount==0 and "-" or amount .. "ft")
	end

	gui.set_text(nodes["pokemon/traits/txt_darkvision"], "-")
	gui.set_text(nodes["pokemon/traits/txt_tremorsense"], "-")
	gui.set_text(nodes["pokemon/traits/txt_truesight"], "-")
	gui.set_text(nodes["pokemon/traits/txt_blindsight"], "-")
	local senses = _pokemon.get_senses(pokemon)
	if next(senses) ~= nil then
		for _, str in pairs(senses) do
			local split = utils.split(str)
			gui.set_text(nodes["pokemon/traits/txt_" .. split[1]:lower()], split[2])
		end
	end
	local g = {
		[_pokemon.GENDERLESS] = "transparent",
		[_pokemon.MALE] = "male",
		[_pokemon.FEMALE] = "female"
	}
	local genderized, gender = _pokemon.genderized(pokemon)
	if not genderized then
		gender = _pokemon.get_gender(pokemon)
	end
	if gender ~= nil then
		gui.set_enabled(nodes["pokemon/gender_icon"], true)
		gui.play_flipbook(nodes["pokemon/gender_icon"], g[gender])
	else
		gui.set_enabled(nodes["pokemon/gender_icon"], false)
	end
end

function M.on_input(action_id, action)
	if not active then
		return
	end

	if item_button then
		gooey.button(item_button, action_id, action, function()
			local item = _pokemon.get_held_item(active_pokemon)
			monarch.show(screens.INFO, nil, {text=items.get_description(item)})
		end)
	end

	gooey.button(rest_button, action_id, action, function() 
		monarch.show(screens.ARE_YOU_SURE, nil, {title="Pokémon Center", text="We heal your Pokémon back to perfect health!\nShall we heal your Pokémon?", sender=msg.url(), id="full_rest"})
	end)
end

function M.create(nodes, pokemon, index)
	item_button = nil
	active = nodes
	active_pokemon = pokemon
	rest_button = gui.get_id(active["pokemon/btn_rest"])
	setup_main_information(nodes, pokemon)
	setup_info_tab(nodes, pokemon)
	scrollhandler.set_max(index, 3, gui.get_position(active["pokemon/traits/scroll_stop"]).y)
end

function M.on_message(message_id, message, sender)
	if message_id == messages.RESPONSE and message.response then
		if message.id == "full_rest" then
			_pokemon.reset_in_storage(active_pokemon)
			msg.post(url.PARTY, messages.REFRESH_STATUS)
			msg.post(url.PARTY, messages.REFRESH_HP)
			msg.post(url.PARTY, messages.REFRESH_PP)
		end
	end
end


return M
