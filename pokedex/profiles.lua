local monarch = require "monarch.monarch"
local defsave = require "defsave.defsave"

local M = {}

local profiles
local active

function M.add(profile_name, slot)
	slot = slot or 1
	local profile = {name=profile_name, seen=0, caught=0}
	profiles[slot] = profile
end

function M.delete(slot)
	profiles[slot] = nil
end

function M.is_new_game()
	return not next(profiles)
end

function M.get_all_profiles()
	return profiles
end

function M.set_active(profile_name)
	active = profile_name
end

function M.get_active()
	return active or "pokedex5e"
end

function load_profiles()
	local loaded = defsave.load("profiles")
	if loaded then
		profiles = defsave.get("profiles", "profiles").profiles
	end
	if not profiles then
		profiles = {}
	end
end

function M.init()
	load_profiles()
end

return M