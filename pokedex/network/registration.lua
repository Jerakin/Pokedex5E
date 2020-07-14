local initial_connection = require "pokedex.network.initial_connection"
local send_pokemon = require "pokedex.network.send_pokemon"

local M = {}

function M.init()
	initial_connection.init()
	send_pokemon.init()
end

return M