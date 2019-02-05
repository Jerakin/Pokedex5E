local monarch = require "monarch.monarch"
local defsave = require "defsave.defsave"
local md5 = require "utils.md5"
local M = {}

local profiles
local active_slot

local function generate_id()
	local m = md5.new()
	m:update(tostring(socket.gettime()))
	return md5.tohex(m:finish()):sub(1, 5)
end

function M.add(profile_name, slot)
	slot = slot or 1
	local profile = {name=profile_name, seen=0, caught=0, file_name=profile_name .. generate_id()}
	profiles[slot] = profile
	M.save()
	return slot
end

function M.update(profile_name, data)
	for _, profile in pairs(profiles) do
		if profile.name == profile_name then
			profile.caught = data.caught
		end
	end
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

function M.set_active(slot)
	active_slot = slot
end

function M.save()
	defsave.set("profiles", "profiles", profiles)
	defsave.save("profiles")
end

function M.get_active()
	return active_slot
end

function M.get_active_file_name()
	return profiles[active_slot].file_name
end

function M.get_active_name()
	return profiles[active_slot].name
end

function load_profiles()
	local loaded = defsave.load("profiles")
	profiles = defsave.get("profiles", "profiles")

	-- Clean up corrupted profiles
	for k, p in pairs(profiles) do
		if not defsave.file_exists(p.file_name) then
			profiles[k] = nil
		end
	end
end

function M.init()
	load_profiles()
end

return M