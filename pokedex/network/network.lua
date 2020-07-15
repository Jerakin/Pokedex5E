local netcore = require "pokedex.network.netcore"
local net_members = require "pokedex.network.net_members"
local send_pokemon = require "pokedex.network.send_pokemon"

local M = {}

function M.init()
	netcore.init()

	net_members.init()
	send_pokemon.init()
end

function M.update()
	net_members.update()
	
	netcore.update()
end

function M.final()
	net_members.final()
	
	netcore.final()
end

return M