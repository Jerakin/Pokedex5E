local defsave = require "defsave.defsave"
local monarch = require "monarch.monarch"
local _pokemon = require "pokedex.pokemon"
local storage = require "pokedex.storage"
local pokedex = require "pokedex.pokedex"
local nature = require "pokedex.natures"
local defsave = require "defsave.defsave"
local movedex = require "pokedex.moves"
local generate = require "screens.generate_pokemon.generate_pokemon"
local backup = require "utils.backup"


local M = {}

M.loaded_backup = false
M.SHARE = false

local function add_pokemon(species)
	local level = math.min(rnd.range(1, 20), pokedex.get_minimum_wild_level(species))
	generate.add_pokemon(species, level)
end


function M.add_pokemon(amount)
	amount = amount or 1
	local save = defsave.save
	defsave.save = function() end
	for i=1, amount do
		local random_pokemon = pokedex.list[rnd.range(1, #pokedex.list)]
		add_pokemon(random_pokemon)
	end
	defsave.save = save
end


function M.add_all_pokemon()
	local save = defsave.save
	defsave.save = function() end
	for _, species in pairs(pokedex.list) do
		add_pokemon(species)
	end
	defsave.save = save
end

function M.load_backup()
	local success, file_path = diags.open()
	if success == diags.OKAY then
		backup.load_backup(file_path)
		M.loaded_backup = true
	end
end

function M.add_all_moves()
	local inventory = storage.list_of_ids_in_inventory()
	local per_pokemon = 10 --#movedex.list / 6
	print("Adding " .. per_pokemon .. " moves to each Pokemon")
	local pkmn = storage.get_copy(inventory[1])
	local move_index = 1
	local pokemon_index = 1
	print("Pokemon number " .. pokemon_index .. " done")
	for i=1, per_pokemon*#inventory do
		if i > 4 then 
			_pokemon.add_feat(pkmn, "Extra Move")
		end
		local move = movedex.list[rnd.range(1, #movedex.list)]
		_pokemon.set_move(pkmn, move, move_index)
		move_index = move_index + 1
		if move_index-1 > per_pokemon then
			if pokemon_index == 7 then
				break
			end
			storage.update_pokemon(pkmn)
			move_index = 1
			pokemon_index = pokemon_index + 1
			print("Pokemon number " .. pokemon_index .. " done")
			pkmn = storage.get_copy(inventory[pokemon_index])
		end
	end
end

return M