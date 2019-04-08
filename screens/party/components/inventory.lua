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


local function create_party_indicators(pokemons_in_party)
	for i=1, 6 do
		local id = pokemons_in_party[i]
		local party_sprite = gui.get_node("party_indicator/pokemon_" .. i .. "/pokemon_sprite")
		if id then
			local pokemon = storage.get_copy(id)
			local pokemon_sprite, _ = _pokemon.get_sprite(pokemon)
			gui.play_flipbook(party_sprite, pokemon_sprite)
			local b = {node="party_indicator/pokemon_" .. i .. "/pokemon_sprite", func=function() activate_pokemon(i) end}
			table.insert(buttons, b)
		else
			gui.set_scale(party_sprite, vmath.vector3(1))
			gui.set_texture(party_sprite, "gui")
			gui.set_color(party_sprite, gui_colors.INACTIVE)
			gui.play_flipbook(party_sprite, "sort_type")
		end
	end
end


function M.create()
	local party_pokemons = storage.list_of_ids_in_inventory()
	create_party_indicators(party_pokemons)
end

function M.on_input(action_id, action)
	for _, b in pairs(buttons) do
		gooey.button(b.node, action_id, action, b.func)
	end
end

return M