local profiles = require "pokedex.profiles"


local M = {}

local dex = {}

M.states = {SEEN=1, CAUGHT=2, UNENCOUNTERED=3}

function M.set(species, state)
	if state == 3 then
		state = nil
	end
	dex[species] = state
end

function M.get(species)
	return dex[species] or M.states.UNENCOUNTERED
end

function M.init()
	local profile = profiles.get_active()
	dex = profile.pokedex or {}
end

function M.save()
	profiles.update(profiles.get_active_slot(), {pokedex=dex})
	pprint(dex)
end

return M