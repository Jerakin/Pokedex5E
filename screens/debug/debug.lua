local defsave = require "defsave.defsave"
local monarch = require "monarch.monarch"
local _pokemon = require "pokedex.pokemon"
local storage = require "pokedex.storage"
local pokedex = require "pokedex.pokedex"
local nature = require "pokedex.natures"
local defsave = require "defsave.defsave"
local movedex = require "pokedex.moves"
local generate = require "screens.generate_pokemon.generate_pokemon"

local M = {}
local function add_pokemon(species)
	local level = math.min(math.random(20), pokedex.get_minimum_wild_level(species))
	generate.add_pokemon(species, level)
end


function M.add_pokemon(amount)
	amount = amount or 1
	local save = defsave.save
	defsave.save = function() end
	for i=1, amount do
		local random_pokemon = pokedex.list[math.random(#pokedex.list)]
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

return M