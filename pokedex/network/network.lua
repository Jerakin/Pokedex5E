local netcore = require "pokedex.network.netcore"
local net_connection = require "pokedex.network.net_connection"
local net_members = require "pokedex.network.net_members"
local net_member_name = require "pokedex.network.net_member_name"
local send_pokemon = require "pokedex.network.send_pokemon"
local profiles = require "pokedex.profiles"

local initialized = false
local M = {}

function M.init()
	if not initialized then
		netcore.init()

		net_connection.init()
		net_members.init()
		net_member_name.init()
		
		send_pokemon.init()


		local profile = profiles.get_active()
		if profile then
			M.load(profile)
		end
		initialized = true
	end
end

function M.update()
	net_connection.update()

	netcore.update()
end

function M.final()
	net_connection.final()
	net_members.final()
	
	netcore.final()
end

function M.load(profile)
	net_connection.load(profile)
	net_members.load(profile)
	
	netcore.load(profile)
end

function M.save()
	net_connection.save()
	net_members.save()
	
	netcore.save()
end

return M