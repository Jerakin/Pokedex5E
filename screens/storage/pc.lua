local storage_list = require "screens.storage.storage_list"
local storage = require "pokedex.storage"
local _pokemon = require "pokedex.pokemon"
local monarch = require "monarch.monarch"
local flow = require "utils.flow"
local M = {}

local pokemon_ids = {}
local nodes = {}

local scroll_node
local stencil_node
local template_node
local COLUMNS = 3
local storage_cache = nil

local DISTANCE = vmath.vector3(200, 200, 0)

local STORAGE_UPDATING = false

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

sprite_position = vmath.vector3()
start_position = vmath.vector3(-210, -100, 0)

local function add_to_storage(id, state)
	local i = #pokemon_ids + 1
	local n = gui.clone_tree(template_node)
	local pokemon = storage.get_copy(id)
	local sprite = n["pokemon_entry/pokemon_sprite"]
	local text = n["pokemon_entry/txt_pokemon"]
	local root =  n["pokemon_entry/root"]

	sprite_position.x = start_position.x + math.fmod(i-1, COLUMNS) * DISTANCE.x
	sprite_position.y = start_position.y - (math.ceil(i/COLUMNS)-1) * DISTANCE.y
	if not state then
		gui.set_color(sprite, vmath.vector4(0.4,0.4,0.4,1))
	end
	gui.set_parent(root, scroll_node)
	gui.set_position(root, sprite_position)
	set_pokemon_text(text, pokemon)
	set_pokemon_sprite(sprite, pokemon)
	table.insert(pokemon_ids, id)
	table.insert(nodes,root)
end

local function create_inventory()
	for _, id in pairs(storage.list_of_ids_in_inventory()) do
		add_to_storage(id, false)
	end
end

local function create_pc()
	for i, id in pairs(storage.list_of_ids_in_storage()) do
		--flow.start(function()
			--flow.frames(1)
			add_to_storage(id, true)
		--end)
	end
end

local function create_storage_list()
	flow.start(function()
		STORAGE_UPDATING = true
		for _, n in pairs(nodes) do
			gui.delete_node(n)
		end

		pokemon_ids = {}
		nodes = {}
		storage_cache = storage.list_of_ids_in_inventory()
		flow.frames(1)
		create_inventory()
		create_pc()
		flow.delay(1)
		STORAGE_UPDATING = false
	end)
end

function M.filtered_pokemons(pokemons)
	M.redraw(pokemons)
end

function M.redraw()
	if storage_cache and not is_storage_updated(storage_cache, storage.list_of_ids_in_inventory()) then
		return
	end
	create_storage_list(pokemons)
	storage_list.update(nodes)
end

local function select_item(state)
	local id = pokemon_ids[state.index]
	local to = "inventory"
	for _, i in pairs(storage.list_of_ids_in_inventory()) do
		if i == id then
			to = "storage"
		end
	end
	monarch.show("transfer_pokemon", {}, {id=id, to=to})
end


function M.setup(stencil, scroll, template)
	stencil_node = stencil
	scroll_node = scroll
	template_node = template
	flow.start(function()
	create_storage_list()
	storage_list.create(stencil_node, scroll_node, nodes)
end)
end

function M.on_input(action_id, action)
	if STORAGE_UPDATING then
		return
	end
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