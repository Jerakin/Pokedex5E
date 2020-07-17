local net_members = require "pokedex.network.net_members"
local profiles = require "pokedex.profiles"

local NAME_KEY = "name"

local M = {}

local function active_profile_name_changed()
	net_members.update_member_data(NAME_KEY, profiles.get_active_name())
end

function M.init()
	if not initialized then
		profiles.register_active_name_changed_cb(active_profile_name_changed)
		active_profile_name_changed()
		
		initialized = true
	end
end

function M.get_name(member_id)
end

return M