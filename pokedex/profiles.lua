local monarch = require "monarch.monarch"
local defsave = require "defsave.defsave"
local md5 = require "utils.md5"
local log = require "utils.log"
local M = {}

local profiles = {}
local active_slot

local function generate_id()
	local m = md5.new()
	m:update(tostring(socket.gettime()))
	return md5.tohex(m:finish()):sub(1, 5)
end

function M.add(profile_name, slot)
	slot = slot or 1
	local profile = {
		slot=slot,
		name=profile_name,
		seen=0,
		caught=0,
		released=0,
		file_name=profile_name .. generate_id()
	}
	profiles[slot] = profile
	M.save()
	return profile
end

function M.update(slot, data)
	for key, value in pairs(data) do
		if not profiles[slot] then
			local e = "Can not find slot '" .. tostring(slot) .. "' in profile\n" .. debug.traceback()
			gameanalytics.addErrorEvent {
				severity = "Critical",
				message = e
			}
			log.error(e)
		end
		profiles[slot][key] = value
	end
	M.save()
end

function M.delete(slot)
	local f_name = M.get_file_name(slot)
	defsave.delete(f_name)
	profiles[slot] = nil
	M.save()
end

function M.is_new_game()
	if profiles then
		if next(profiles) then
			return false
		end
	end
	return true
end

function M.get_all_profiles()
	return profiles
end

function M.set_active(slot)
	active_slot = slot
	profiles.last_used = slot
	M.save()
end

function M.save()
	defsave.set("profiles", "profiles", profiles)
	defsave.save("profiles")
end

function M.get_active()
	return profiles[active_slot]
end

function M.get_active_slot()
	return active_slot
end

function M.get_active_file_name()
	return M.get_file_name(active_slot)
end

function M.get_file_name(slot)
	return profiles[slot].file_name
end

function M.get_active_name()
	if profiles[active_slot] then
		return profiles[active_slot].name
	else
		local e = "Can not find active_slot \n" .. debug.traceback()
		gameanalytics.addErrorEvent {
			severity = "Critical",
			message = e
		}
		log.error(e)
	end
end

function M.set_party(party)
	profiles[active_slot].party = party
	M.save()
end

function M.get_latest()
	return profiles.last_used
end

local function load_profiles()
	local loaded = defsave.load("profiles")
	profiles = defsave.get("profiles", "profiles")
end

function M.init()
	load_profiles()
	local latest = M.get_latest()
	if latest then
		M.set_active(latest)
	end
end

return M