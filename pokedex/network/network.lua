local netcore = require "pokedex.network.netcore"
local validated_connection = require "pokedex.network.validated_connection"
local membership = require "pokedex.network.membership"
local send_pokemon = require "pokedex.network.send_pokemon"

local M = {}

function M.init()
	netcore.init()

	membership.init()
	send_pokemon.init()
	validated_connection.init()
end

function M.update()
	netcore.update()
end

function M.final()
	netcore.final()
end

return M