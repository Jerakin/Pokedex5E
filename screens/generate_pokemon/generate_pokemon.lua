local _pokemon = require "pokedex.pokemon"
local storage = require "pokedex.storage"
local pokedex = require "pokedex.pokedex"
local nature = require "pokedex.natures"
local movedex = require "pokedex.moves"
local notify = require "utils.notify"
local utils = require "utils.utils"
local dex = require "pokedex.dex"

local M = {}

function M.add_pokemon(species, level)
	notify.notify(species .. " was added to your team!")
	local starting_moves = utils.shuffle2(pokedex.get_starting_moves(species))
	local pokemon = _pokemon.new({species=species})
	local moves = {}
	for i=1, 4 do
		if starting_moves[i] then
			local pp = movedex.get_move_pp(starting_moves[i])
			moves[starting_moves[i]] = {pp=pp, index=i}
		end
	end
	pokemon.exp = pokedex.get_experience_for_level(level-1)
	pokemon.abilities = pokedex.get_pokemon_abilities(species)
	pokemon.level.caught = level
	pokemon.level.current = level
	pokemon.moves = moves
	pokemon.nature = nature.list[rnd.range(1, #nature.list)]
	dex.set(pokemon.species.current, dex.states.CAUGHT)
	storage.add(pokemon)
end

return M