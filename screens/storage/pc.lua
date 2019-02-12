local storage_list = require "screens.storage.storage_list"
local storage = require "pokedex.storage"
local _pokemon = require "pokedex.pokemon"
local monarch = require "monarch.monarch"
local M = {}

local pokemon_ids = {}
local nodes = {}

local scroll_node
local stencil_node
local template_node
local COLUMNS = 3
local storage_cache = nil

local DISTANCE = vmath.vector3(200, 200, 0)
local function set_pokemon_sprite(sprite, pokemon)
	local pokemon_sprite, texture = _pokemon.get_sprite(pokemon)
	gui.set_texture(sprite, texture)
	gui.play_flipbook(sprite, pokemon_sprite)
end

local function set_pokemon_text(text, pokemon)
	local level = _pokemon.get_current_level(pokemon)
	local species = _pokemon.get_current_species(pokemon)
	gui.set_text(text, species .. "\n" .. "Lv. " .. level)
end

local function is_storage_updated(a, b)
	if #a ~= #b then
		return true
	end
	for i, id in ipairs(a) do
		if b[i] ~= id then
			return true
		end
	end
	return false
end

local function create_storage_list(pokemons)
	for _, n in pairs(nodes) do
		gui.delete_node(n)
	end

	pokemon_ids = {}
	nodes = {}
	local sprite_position = vmath.vector3()
	local start_position = vmath.vector3(-210, -100, 0)
	for i, id in pairs(pokemons) do
		local n = gui.clone_tree(template_node)
		local pokemon = storage.get_copy(id)
		local sprite = n["pokemon_entry/pokemon_sprite"]
		local text = n["pokemon_entry/txt_pokemon"]
		local root =  n["pokemon_entry/root"]
		
		sprite_position.x = start_position.x + math.fmod(i-1, COLUMNS) * DISTANCE.x
		sprite_position.y = start_position.y - (math.ceil(i/COLUMNS)-1) * DISTANCE.y
		gui.set_parent(root, scroll_node)
		gui.set_position(root, sprite_position)
		set_pokemon_text(text, pokemon)
		set_pokemon_sprite(sprite, pokemon)
		table.insert(pokemon_ids, id)
		table.insert(nodes,root)
	end
	storage_cache = pokemons
end

function M.filtered_pokemons(pokemons)
	M.redraw(pokemons)
end

function M.redraw(pokemons)
	if storage_cache and not is_storage_updated(storage_cache, pokemons) then
		return
	end
	create_storage_list(pokemons)
	storage_list.update(nodes)
end

local function select_item(state)
	monarch.show("move_pokemon", {clear=true}, {id=pokemon_ids[state.index], to="inventory"})
end


function M.setup(stencil, scroll, template)
	stencil_node = stencil
	scroll_node = scroll
	template_node = template
	create_storage_list(storage.list_of_ids_in_storage())
	
	storage_list.create(stencil_node, scroll_node, nodes)
end

function M.on_input(action_id, action)
	local state = storage_list.on_input(action_id, action)
	if state.long_pressed then

	elseif state.released_item_now  then
		if state.selected_item == state.released_item_now then
			select_item(state)
		end
	end	
end

function M.final()
	nodes = {}
	scroll_node = nil
	stencil_node = nil
	template_node = nil
end


return M