local _pokemon = require "pokedex.pokemon"
local party_utils = require "screens.party.utils"
local pokedex = require "pokedex.pokedex"
local gooey = require "gooey.gooey"
local gooey_buttons = require "utils.gooey_buttons"
local storage = require "pokedex.storage"
local information = require "screens.party.components.information"
local monarch = require "monarch.monarch"
local gui_colors = require "utils.gui_colors"
local screens = require "utils.screens"
local messages = require "utils.messages"

local M = {}

local active_buttons = {}
local active_pokemon_id
local active_nodes 


local function update_hp_meter(nodes, max, current, temp_hp)
	local max_size = gui.get_size(nodes["pokemon/hp_bar_bg"])

	local node_cur = nodes["pokemon/hp_bar_bg1"]
	local size_cur = gui.get_size(node_cur)
	local pos_cur = gui.get_position(node_cur)

	local node_over = nodes["pokemon/hp_bar_bg2"]
	local size_over = gui.get_size(node_over)
	local pos_over = gui.get_position(node_over)

	local node_temp_bar = nodes["pokemon/hp_bar_bg_temp"]
	local size_temp = gui.get_size(node_temp_bar)
	local pos_temp = gui.get_position(node_temp_bar)

	temp_hp = math.max(0, temp_hp) -- just in case
	local current_not_over = math.max(0, math.min(current, max))
	local over = math.max(0, current-max)
	local total_max = math.max(max+over+temp_hp, 1) -- avoid divide by 0
	
	-- Set current HP size based on current HP's percentage of total_max
	local percent_cur = current_not_over/total_max
	size_cur.x = math.max(math.min(percent_cur * max_size.x, max_size.x), 0)
	gui.set_size(node_cur, size_cur)

	-- If there's somehow an overage (not sure why this is possible, but I didn't want to break old behavior), display that next to the current bar
	local percent_over = over / total_max
	size_over.x = math.max(math.min(percent_over * max_size.x, max_size.x), 0)
	pos_over.x = pos_cur.x + size_cur.x
	gui.set_size(node_over, size_over)
	gui.set_position(node_over, pos_over)

	-- Set temp HP size and position based on temp HP's percentage of total_max, shifted over to sit next to current/over bars
	local percent_temp = temp_hp / total_max
	size_temp.x = math.max(math.min(percent_temp * max_size.x, max_size.x), 0)
	gui.set_size(node_temp_bar, size_temp)

	pos_temp.x = pos_over.x + size_over.x
	gui.set_position(node_temp_bar, pos_temp)
	
	gui.set_enabled(node_temp_bar, temp_hp > 0)

	local color = gui_colors.HEALTH_HEALTHY
	
	if current / max < 0.32 then
		color = gui_colors.HEALTH_CRITICAL
	elseif current / max < 0.75 then
		color = gui_colors.HEALTH_DAMAGED
	end

	gui.set_color(node_cur, color)
end


local function add_hp(pkmn, hp)
	local current = _pokemon.get_current_hp(pkmn)
	local max = _pokemon.get_total_max_hp(pkmn)
	local temp = _pokemon.get_temp_hp(pkmn)
	local new_temp
	local new_hp

	if hp > 0 then
		new_hp = math.min(current + hp, max)
		new_temp = temp + new_hp + hp - max
		if hp > 1 then
			new_temp = temp
		end	
	else
		new_temp = temp + hp
		new_hp = current + new_temp
	end
	_pokemon.set_temp_hp(pkmn, math.max(new_temp, 0))
	_pokemon.set_current_hp(pkmn, new_hp)

	storage.save()
end

local function set_temp_hp(pkmn, temp_hp)
	_pokemon.set_temp_hp(pkmn, temp_hp)
	storage.save()
end

local function add_loyalty(pkmn, loyalty)
	local current = _pokemon.get_loyalty(pkmn)
	_pokemon.set_loyalty(pkmn, current + loyalty)
	storage.save()
end

local function show_hp_selector(pkmn)
	local hp = _pokemon.get_current_hp(pkmn)
	monarch.show(screens.INPUT, {},
	{
		sender=msg.url(),
		message=messages.UPDATE_HP,
		allowed_characters="[%d%+%-]",
		default_text=hp,
		help_text="Specify new HP (55), subtract (-2), or add (+2)"
	})
end

local function show_temp_hp_selector(pkmn)
	local temp_hp = _pokemon.get_temp_hp(pkmn)
	monarch.show(screens.INPUT, {},
	{
		sender=msg.url(),
		message=messages.UPDATE_TEMP_HP,
		allowed_characters="[%d]",
		default_text=temp_hp,
		help_text="Specify temporary HP.\n\nReminder: Temporary HP does not stack!"
	})
end

local function reduce_hp(pkmn)
	local temp_hp = _pokemon.get_temp_hp(pkmn)
	if temp_hp > 0 then
		set_temp_hp(pkmn, temp_hp-1)
	else
		add_hp(pkmn, -1)
	end
end

local function setup_hp(nodes, pkmn)
	local max = _pokemon.get_total_max_hp(pkmn)
	local current = _pokemon.get_current_hp(pkmn)
	local temp_hp = _pokemon.get_temp_hp(pkmn)
	local hp_text = "HP: " .. current 
	if temp_hp > 0 then
		hp_text = hp_text .. "/" .. max .. " +" .. temp_hp
	else
		hp_text = hp_text .. "/ " .. max
	end
	gui.set_text(nodes["pokemon/txt_hp"],hp_text)
	update_hp_meter(nodes, max, current, temp_hp)
end

local function add_hp_buttons(nodes, pkmn)
	local id = party_utils.set_id(nodes["pokemon/hp_bar_bg"])
	local hp_bar = {
		node=id,
		func=function(button)
			if button.long_pressed then
				show_temp_hp_selector(pkmn)
			else
				show_hp_selector(pkmn)
			end
		end,
		long_pressed_time = 0.5
	}
	
	local id = party_utils.set_id(nodes["pokemon/hp/btn_plus"])
	local plus = {
		node=id,
		func=function(button)
			if button.long_pressed then
				show_temp_hp_selector(pkmn)
			else
				add_hp(pkmn, 1)
				information.refresh(_pokemon.get_id(pkmn))
				setup_hp(nodes, pkmn)
			end
		end,
		refresh=gooey_buttons.plus_button,
		long_pressed_time = 0.5
	}
	
	local id = party_utils.set_id(nodes["pokemon/hp/btn_minus"])

	local minus = {node=id, func=function()
		reduce_hp(pkmn)
		information.refresh(_pokemon.get_id(pkmn))
		setup_hp(nodes, pkmn) end, refresh=gooey_buttons.minus_button
	}

	table.insert(active_buttons, hp_bar)
	table.insert(active_buttons, plus)
	table.insert(active_buttons, minus)
end

local function add_loyalty_buttons(nodes, pkmn)
	local id = party_utils.set_id(nodes["pokemon/loyalty/btn_plus"])
	local plus = {node=id, func=function()
		local pokemon_id = _pokemon.get_id(pkmn)
		add_loyalty(pkmn, 1)
		information.refresh(pokemon_id)
		gui.set_text(nodes["pokemon/txt_loyalty"], party_utils.add_operation(_pokemon.get_loyalty(pkmn)))
		setup_hp(nodes, pkmn)
	end, refresh=gooey_buttons.plus_button}
	
	local id = party_utils.set_id(nodes["pokemon/loyalty/btn_minus"])

	local minus = {node=id, func=function()
		local pokemon_id = _pokemon.get_id(pkmn)
		add_loyalty(pkmn, -1)
		information.refresh(pokemon_id)
		gui.set_text(nodes["pokemon/txt_loyalty"], party_utils.add_operation(_pokemon.get_loyalty(pkmn)))
		setup_hp(nodes, pkmn)
	end, refresh=gooey_buttons.minus_button}
	
	table.insert(active_buttons, plus)
	table.insert(active_buttons, minus)
end

local function setup_exp(nodes, pkmn)
	local current_level = _pokemon.get_current_level(pkmn)
	local max = pokedex.get_experience_for_level(current_level)
	local offset = pokedex.get_experience_for_level(current_level - 1)
	local exp = _pokemon.get_exp(pkmn)
	local node_text = nodes[hash("pokemon/txt_exp")]
	local node_bar = nodes[hash("pokemon/exp_bar")]
	local node_max = nodes[hash("pokemon/exp_bar_bg")]
	local max_size = gui.get_size(node_max)
	local percent = (exp-offset)/(max-offset)
	local size = gui.get_size(node_bar)

	size.x = math.max(math.min(percent * max_size.x, max_size.x), 0)
	gui.set_size(node_bar, size)
	gui.set_text(node_text, "EXP: " .. exp .. "/" .. max)
end



function M.create(nodes, pokemon_id)
	local pkmn = storage.get_pokemon(pokemon_id)
	active_nodes = nodes
	active_pokemon_id = pokemon_id
	active_buttons = {}
	gui.set_text(nodes["pokemon/txt_loyalty"], party_utils.add_operation(_pokemon.get_loyalty(pkmn)))
	add_loyalty_buttons(nodes, pkmn)
	setup_hp(nodes, pkmn)
	add_hp_buttons(nodes, pkmn)
	setup_exp(nodes, pkmn)
	
	gui.set_color(nodes["pokemon/hp_bar_bg2"], gui_colors.HEALTH_ABOVE_MAX)
	gui.set_color(nodes["pokemon/hp_bar_bg"], gui_colors.HEALTH_MISSING)
	gui.set_color(nodes["pokemon/hp_bar_bg_temp"], gui_colors.HEALTH_TEMPORAY)
	
	for _, b in pairs(active_buttons) do
		if b.long_pressed_time then
			gooey.button(b.node).set_long_pressed_time(b.long_pressed_time)
		end
	end
end

function M.on_input(action_id, action)
	for _, b in pairs(active_buttons) do
		gooey.button(b.node, action_id, action, b.func, b.refresh)
	end
end

local function parse_number(str, current)
	local value
	local err
	local expr
	if string.find(str, "[+-]") ~= nil then
		local fnc = loadstring("return " .. current .. str)
		if fnc == nil then
			-- Loadstring didn't compile, this shouldn't happen but tracking have shown it does, report the error.
			local e = string.format("Could not compile the load string: 'return " .. tostring(current) .. tostring(str) .. "'")
			gameanalytics.addErrorEvent {
				severity = "Critical",
				message = e
			}
			log.error(e)
			return current
		end
		value, err = fnc()
		if value ~= nil then
			value = value - current
		else
			local e = "Party:HP:Error" .. err
			log.error(e)

			gameanalytics.addErrorEvent {
				severity = "Error",
				message = e
			}
			
			value = current
		end
		expr = true
	else
		expr = false
		value = tonumber(str) - current
	end
	return value, expr
end

function M.on_message(message_id, message)
	local active_pokemon_id = storage.list_of_ids_in_party()[message.active_index]
	local pkmn = storage.get_pokemon(active_pokemon_id)
	
	if message_id == messages.UPDATE_EXP then
		local current_exp = _pokemon.get_exp(pkmn)
		local min = pokedex.get_experience_for_level(_pokemon.get_current_level(pkmn) - 1)
		local exp, expr = parse_number(message.str, current_exp)
		exp = math.max(min, current_exp + exp)
		_pokemon.set_exp(pkmn, exp)
		setup_exp(active_nodes, pkmn)
		storage.save()
	elseif message_id == messages.UPDATE_HP then
		local current_hp = _pokemon.get_current_hp(pkmn)
		local hp, _ = parse_number(message.str, current_hp)
		add_hp(pkmn, hp)
		setup_hp(active_nodes, pkmn)
		information.refresh(active_pokemon_id)
	elseif message_id == messages.REFRESH_HP then
		setup_hp(active_nodes, pkmn)
	elseif message_id == messages.UPDATE_TEMP_HP then
		local temp_hp, expr = parse_number(message.str, 0)
		if not expr then
			set_temp_hp(pkmn, math.max(temp_hp, 0))
			setup_hp(active_nodes, pkmn)
		end
	end
end

return M