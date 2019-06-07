local profiles = require "pokedex.profiles"


local M = {}

local dex = {}

local states = {SEEN=1, CAUGHT=2, UNENCOUNTERED=3}

function M.caught(species)
	dex[species] = states.CAUGHT
end

function M.seen(species)
	dex[species] = states.SEEN
end

function M.get(species)
	return rnd.range(1, 3)
end

function M.load()
	local profile = profiles.get_active()
	dex = profile.pokedex or {}
end

return M