local net_members = require "pokedex.network.net_members"
local profiles = require "pokedex.profiles"
local broadcast = require "utils.broadcast"
local messages = require "utils.messages"

local NAME_KEY = "name"

local M = {}

local function active_profile_name_changed()
	net_members.update_member_data(NAME_KEY, profiles.get_active_slot() and profiles.get_active_name() or nil)
end

function M.init()
	broadcast.register(messages.AFTER_PROFILE_CHANGE, active_profile_name_changed)
	active_profile_name_changed()
end

function M.get_name(member_id)
	return net_members.get_data_for_member(NAME_KEY, member_id) or "Someone"
end

return M