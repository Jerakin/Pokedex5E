local netcore = require "pokedex.network.netcore"
local net_groups = require "pokedex.network.net_groups"
local net_ip = require "pokedex.network.net_ip"
local net_members = require "pokedex.network.net_members"
local net_member_name = require "pokedex.network.net_member_name"
local send_pokemon = require "pokedex.network.send_pokemon"
local profiles = require "pokedex.profiles"

local initialized = false
local M = {}

function M.init()
	if not initialized then
		netcore.init()

		net_groups.init()
		net_ip.init()
		net_members.init()
		net_member_name.init()

		send_pokemon.init()

		local profile = profiles.get_active()
		if profile then
			M.load_profile(profile)
		end
		initialized = true
	end
end

function M.update()
	netcore.update()
end

function M.final()
	net_members.final()
	
	netcore.final()
end

function M.load_profile(profile)
	net_members.load_profile(profile)
	
	netcore.load_profile(profile)
end

function M.save()
	net_members.save()
	
	netcore.save()
end

return M