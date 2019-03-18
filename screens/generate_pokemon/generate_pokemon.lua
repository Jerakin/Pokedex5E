local _pokemon = require "pokedex.pokemon"
local storage = require "pokedex.storage"
local pokedex = require "pokedex.pokedex"
local nature = require "pokedex.natures"
local movedex = require "pokedex.moves"
local notify = require "utils.notify"

local M = {}

function M.add_pokemon(species, level)
	notify.notify(species .. " was added to your team!")
	level = level or 5
	local starting_moves = pokedex.get_starting_moves(species)
	local pokemon = _pokemon.new({species=species})
	local moves = {}
	for i=1, 4 do
		if starting_moves[i] then
			local pp = movedex.get_move_pp(starting_moves[i])
			moves[starting_moves[i]] = {pp=pp, index=i}
		end
	end
	pokemon.level.caught = level
	pokemon.level.current = level
	pokemon.moves = moves
	pokemon.nature = nature.list[math.random(#nature.list)]
	storage.add(pokemon)
end

return M