local storage = require "pokedex.storage"
local _pokemon = require "pokedex.pokemon"
local button = require "utils.button"
local monarch = require "monarch.monarch"
local flow = require "utils.flow"
local M = {}

local inventory_buttons = {}


local function set_pokemon_sprite(sprite, pokemon)
	local pokemon_sprite, texture = _pokemon.get_sprite(pokemon)
	gui.set_texture(sprite, "sprite0")
	gui.play_flipbook(sprite, pokemon_sprite)
end

function M.redraw()
	for _, b in pairs(inventory_buttons) do
		button.unregister(b)
	end

	M.setup()
end

local function inventory_button(node, id)
	return button.register(node, function()
		monarch.show("transfer_pokemon", {}, {id=id, to="storage"})
	end)
end

function M.setup()
	local inventory = storage.list_of_ids_in_inventory()
	local left_in_storage = #storage.list_of_ids_in_storage()
	inventory_buttons = {}
	for i=1, 6 do
		local sprite = gui.get_node("inventory_pokemon_" .. i .. "/pokemon_sprite")
		local pokemon = storage.get_copy(inventory[i])
		if pokemon then
			gui.set_scale(sprite, vmath.vector3(3))	
			set_pokemon_sprite(sprite, pokemon)
			table.insert(inventory_buttons, inventory_button(sprite, inventory[i]))
		else
			gui.set_scale(sprite, vmath.vector3(1))
			gui.set_texture(sprite, "gui")
			if left_in_storage > 0 then
				gui.play_flipbook(sprite, "pokeball_add")
				gui.set_scale(sprite, vmath.vector3(1, 1, 1))
			else
				gui.play_flipbook(sprite, "pokeball")
			end
			left_in_storage = left_in_storage - 1
		end
	end
end


function M.on_input(action_id, action)
	button.on_input(action_id, action)
end

function M.final()
	for _, b in pairs(inventory_buttons) do
		button.unregister(b)
	end
end

return M