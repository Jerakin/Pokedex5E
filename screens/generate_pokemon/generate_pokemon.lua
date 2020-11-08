local _pokemon = require "pokedex.pokemon"
local storage = require "pokedex.storage"
local pokedex = require "pokedex.pokedex"
local nature = require "pokedex.natures"
local movedex = require "pokedex.moves"
local notify = require "utils.notify"
local utils = require "utils.utils"
local dex = require "pokedex.dex"

local M = {}

function M.add_pokemon(species, variant, level)
	notify.notify(species .. " was added to your team!")
	local all_moves = utils.shuffle2(utils.merge(pokedex.get_starting_moves(species), pokedex.get_moves(species, variant, level)))

	local pokemon = _pokemon.new({species=species, variant=variant})
	local moves = {}
	for i=1, 4 do
		if all_moves[i] then
			local pp = movedex.get_move_pp(all_moves[i])
			moves[all_moves[i]] = {pp=pp, index=i}
		end
	end
	
	pokemon.exp = pokedex.get_experience_for_level(level-1)
	pokemon.abilities = pokedex.get_abilities(species)
	pokemon.level.caught = pokedex.get_minimum_wild_level(species)
	pokemon.level.current = level
	pokemon.moves = moves
	pokemon.nature = nature.list[rnd.range(1, #nature.list)]

	local max_hp = _pokemon.get_default_max_hp(pokemon)
	local con = _pokemon.get_attributes(pokemon).CON
	local con_mod = math.floor((con - 10) / 2)
	pokemon.hp.max = max_hp
	pokemon.hp.current = max_hp + (con_mod * level)
	
	dex.set(pokemon.species.current, dex.states.CAUGHT)
	storage.add(pokemon)
end

return M