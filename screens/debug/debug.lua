local defsave = require "defsave.defsave"
local monarch = require "monarch.monarch"
local _pokemon = require "pokedex.pokemon"
local storage = require "pokedex.storage"
local pokedex = require "pokedex.pokedex"
local nature = require "pokedex.natures"
local defsave = require "defsave.defsave"
local movedex = require "pokedex.moves"

local M = {}
local function add_pokemon(species)
	local starting_moves = pokedex.get_starting_moves(species)
	local pokemon = _pokemon.new({species=species})
	local moves = {}
	for i=1, 4 do
		if starting_moves[i] then
			local pp = movedex.get_move_pp(starting_moves[i])
			moves[starting_moves[i]] = {pp=pp, index=i}
		end
	end
	local level = math.random(20)
	pokemon.level.caught = level
	pokemon.level.current = level
	pokemon.moves = moves
	pokemon.nature = nature.list[math.random(#nature.list)]
	storage.add(pokemon)
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