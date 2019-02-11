local storage = require "pokedex.storage"
local _pokemon = require "pokedex.pokemon"
local button = require "utils.button"
local monarch = require "monarch.monarch"
local M = {}

local inventory_buttons = {}


local function set_pokemon_sprite(sprite, pokemon)
	local pokemon_sprite, texture = _pokemon.get_sprite(pokemon)
	gui.set_texture(sprite, texture)
	gui.play_flipbook(sprite, pokemon_sprite)
end

function M.redraw()
	for _, b in pairs(inventory_buttons) do
		button.unregister(b)
	end

	inventory_buttons = {}
	M.setup()
end

local function inventory_button(node, id)
	return button.register(node, function()
		monarch.show("move_pokemon", {clear=true}, {id=id, to="storage"})
	end)
end

function M.setup()
	local inventory = storage.list_of_ids_in_inventory()

	for i=1, 6 do
		local pokemon = storage.get_copy(inventory[i])
		local sprite = gui.get_node("inventory_pokemon_" .. i .. "/pokemon_sprite")
		if pokemon then
			gui.set_enabled(sprite, true)
			set_pokemon_sprite(sprite, pokemon)
			table.insert(inventory_buttons, inventory_button(sprite, inventory[i]))
		end
	end
	
	local free_slots = 6 - #storage.list_of_ids_in_inventory()
	local left_in_storage = #storage.list_of_ids_in_storage()
	for i=#storage.list_of_ids_in_inventory()+1, 6 do
		local pok_sprite = gui.get_node("inventory_pokemon_" .. i .. "/pokemon_sprite")
		left_in_storage = left_in_storage - 1
		gui.set_texture(pok_sprite, "gui")
		if left_in_storage > 0 then
			gui.play_flipbook(pok_sprite, "pokeball_add")
		else
			gui.play_flipbook(pok_sprite, "pokeball")
		end
	end
	
end


function M.on_input(action_id, action)
	button.on_input(action_id, action)
end

function M.final()
	button.unregister()
end

return M