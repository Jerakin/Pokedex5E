local send_pokemon = require "pokedex.network.send_pokemon"

local M = {}

function M.init()
	send_pokemon.init()
end

return M