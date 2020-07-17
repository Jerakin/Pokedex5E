local netcore = require "pokedex.network.netcore"
local net_members = require "pokedex.network.net_members"
local send_pokemon = require "pokedex.network.send_pokemon"
local profiles = require "pokedex.profiles"

local M = {}

function M.init()
	netcore.init()

	net_members.init()
	send_pokemon.init()

	local profile = profiles.get_active()
	if profile then
		M.load(profile)
	end
	initialized = true
end

function M.update()
	netcore.update()
end

function M.final()
	net_members.final()
	
	netcore.final()
end

function M.load(profile)
	net_members.load(profile)
end

function M.save()
	net_members.save()
end

return M