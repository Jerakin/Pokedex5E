local storage = require "pokedex.storage"
local _pokemon = require "pokedex.pokemon"
local gooey = require "gooey.gooey"
local gooey_buttons = require "utils.gooey_buttons"
local gui_colors = require "utils.gui_colors"
local party = require "screens.party.party"
local M = {}

local buttons = {}

local function activate_pokemon(index)
	party.switch_to_slot(index)
end

local function activate_unused_pokemon(index)
	-- User tapped an unused pokeball (empty slot), eat input
end

function M.set_active(index, instant)
	local n = gui.get_node("party_indicator/inventory_pokemon_" .. index .. "/pokemon_sprite")
	local t = gui.get_node("party_indicator/active")
	local pos = gui.get_position(n)
	pos.y = 38
	if instant then
		gui.set_position(t, pos)
	else
		gui.animate(t, "position", pos, gui.EASING_OUTCUBIC, 0.2)
	end
end

local function create_party_indicators(pokemons_in_party)
	for i=1, 6 do
		local id = pokemons_in_party[i]
		local party_sprite = gui.get_node("party_indicator/inventory_pokemon_" .. i .. "/pokemon_sprite")
		if id then
			local pokemon = storage.get_pokemon(id)
			local pokemon_sprite, texture = _pokemon.get_icon(pokemon)
			gui.set_scale(party_sprite, vmath.vector3(2.5))
			gui.set_texture(party_sprite, "gui")
			gui.set_color(party_sprite, gui_colors.WHITE)
			
			gui.set_texture(party_sprite, texture)
			if pokemon_sprite then
				gui.play_flipbook(party_sprite, pokemon_sprite)
			end
			local b = {node="party_indicator/inventory_pokemon_" .. i .. "/pokemon_sprite", func=function() activate_pokemon(i) end}
			table.insert(buttons, b)
		else
			gui.set_scale(party_sprite, vmath.vector3(1))
			gui.set_texture(party_sprite, "gui")
			gui.set_color(party_sprite, gui_colors.INACTIVE)
			gui.play_flipbook(party_sprite, "sort_type")
			
			local b = {node="party_indicator/inventory_pokemon_" .. i .. "/pokemon_sprite", func=function() activate_unused_pokemon(i) end}
			table.insert(buttons, b)
		end
	end
end


function M.create()
	buttons = {}
	local party_pokemons = storage.list_of_ids_in_party()
	create_party_indicators(party_pokemons)
end

local clicked
local inv_b
function M.on_input(action_id, action)
	clicked = false
	for _, b in pairs(buttons) do
		inv_b = gooey.button(b.node, action_id, action, b.func)
		if inv_b.pressed_now then
			clicked = true
		end
	end
	return clicked
end

return M