local _pokemon = require "pokedex.pokemon"
local party_utils = require "screens.party.utils"
local pokedex = require "pokedex.pokedex"
local gooey = require "gooey.gooey"
local gooey_buttons = require "utils.gooey_buttons"
local storage = require "pokedex.storage"
local M = {}

local active_buttons = {}

local current_id

local function update_hp_meter(nodes, max, current)
	local max_size = gui.get_size(nodes["pokemon/hp_bar_bg"])
	local percent = current/max
	local size = gui.get_size(nodes["pokemon/hp_bar_bg1"])

	size.x = math.max(math.min(percent * max_size.x, max_size.x), 0)
	gui.set_size(nodes["pokemon/hp_bar_bg1"], size)
end


function M.add_hp(pokemon, hp)
	local current =_pokemon.get_current_hp(pokemon)
	_pokemon.set_current_hp(pokemon, current + hp)
end

local function add_hp_buttons(nodes, pokemon)
	local id = party_utils.set_id(nodes["pokemon/hp/btn_plus"])
	local plus = {node=id, func=function()
		local pokemon = storage.get_copy(_pokemon.get_id(pokemon))
		M.add_hp(pokemon, 1)
		M.setup_hp(nodes, pokemon) end, refresh=gooey_buttons.plus_button
	}
	local id = party_utils.set_id(nodes["pokemon/hp/btn_minus"])

	local minus = {node=id, func=function()
		local pokemon = storage.get_copy(_pokemon.get_id(pokemon))
		M.add_hp(pokemon, -1)
		M.setup_hp(nodes, pokemon) end, refresh=gooey_buttons.minus_button
	}
	table.insert(active_buttons, plus)
	table.insert(active_buttons, minus)
end

function M.setup_exp(nodes, pokemon)
	local current_level = _pokemon.get_current_level(pokemon)
	local max = pokedex.get_experience_for_level(current_level)
	local offset = pokedex.get_experience_for_level(current_level - 1)
	local exp = _pokemon.get_exp(pokemon)
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

function M.setup_hp(nodes, pokemon)
	local max = _pokemon.get_max_hp(pokemon)
	local current =_pokemon.get_current_hp(pokemon)
	gui.set_text(nodes["pokemon/txt_hp"],"HP: " .. current .. "/ " .. max)
	update_hp_meter(nodes, max, current)
end

function M.create(nodes, pokemon)
	active_buttons = {}
	M.setup_hp(nodes, pokemon)
	add_hp_buttons(nodes, pokemon)
	M.setup_exp(nodes, pokemon)
end

function M.on_input(action_id, action)
	for _, b in pairs(active_buttons) do
		gooey.button(b.node, action_id, action, b.func, b.refresh)
	end
end

return M