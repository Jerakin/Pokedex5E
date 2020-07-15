local monarch = require "monarch.monarch"
local defsave = require "defsave.defsave"
local md5 = require "utils.md5"
local log = require "utils.log"
local net_members = require "pokedex.network.net_members"

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
	if profiles.slots == nil then
		profiles.slots = {}
	end
	
	table.insert(profiles.slots, profile)
	M.save()
	return profile
end

function M.get_slot(slot)
	if slot ~= nil and profiles.slots and #profiles.slots <= slot then
		return profiles.slots[slot]
	end
	return nil
end

function M.update(slot, data)
	for key, value in pairs(data) do
		if not profiles.slots[slot] then
			local e = "Can not find slot '" .. tostring(slot) .. "' in profile\n" .. debug.traceback()
			gameanalytics.addErrorEvent {
				severity = "Critical",
				message = e
			}
			log.error(e)
		end
		profiles.slots[slot][key] = value
	end
	M.save()
end

function M.delete(slot)
	local f_name = M.get_file_name(slot)
	defsave.delete(f_name)
	for index, profile in pairs(M.get_all_profiles()) do
		if index == slot then
			table.remove(profiles.slots, index)
			break
		end
	end
	M.save()
end

function M.is_new_game()
	if profiles and profiles.slots then
		if next(profiles.slots) then
			return false
		end
	end
	return true
end

function M.get_all_profiles()
	return profiles.slots or {}
end

function M.set_active(slot)
	active_slot = slot
	profiles.last_used = slot

	if slot and profiles.slots and profiles.slots[slot] then
		net_members.set_local_member_data(M.get_active_name(), M.get_active_file_name())
	end
	
	M.save()
end

function M.save()
	defsave.set("profiles", "profiles", profiles)
	defsave.save("profiles")
end

function M.get_active()
	return profiles.slots and profiles.slots[active_slot]
end

function M.get_active_slot()
	return active_slot
end

function M.get_active_file_name()
	return M.get_file_name(active_slot)
end

function M.get_file_name(slot)
	return slot ~= nil and profiles.slots[slot].file_name or nil
end

function M.get_active_name()
	if profiles.slots[active_slot] then
		return profiles.slots[active_slot].name
	else
		local e = "Can not find active_slot " .. tostring(active_slot) ..  "\n" .. debug.traceback()
		gameanalytics.addErrorEvent {
			severity = "Critical",
			message = e
		}
		log.error(e)
	end
end

function M.set_active_name(new_name)
	if profiles.slots[active_slot] then
		if profiles.slots[active_slot] ~= new_name then
			profiles.slots[active_slot].name = new_name
			M.save()
		end
	else
		local e = "Can not find active_slot " .. tostring(active_slot) ..  "\n" .. debug.traceback()
		gameanalytics.addErrorEvent {
			severity = "Critical",
			message = e
		}
		log.error(e)
	end
end

function M.set_party(party)
	profiles.slots[active_slot].party = party
	M.save()
end

function M.get_latest()
	if next(profiles) ~= nil then
		if profiles.last_used ~= nil and profiles.last_used <= #profiles.slots then
			return profiles.last_used
		end
	end
end

local function load_profiles()
	local loaded = defsave.load("profiles")
	profiles = defsave.get("profiles", "profiles")
end

local function convert_to_rolling_profile_slot()
	if profiles.slots or next(profiles) == nil then
		return
	end
	
	local new_profiles = {slots={}}
	local counter = 0
	for slot, p in pairs(profiles) do
		if type(p) ~= "number" then
			counter = counter + 1
			table.insert(new_profiles.slots, p)
		end
	end
	log.info("Converted profiles slots")
	active_slot = nil
	profiles = new_profiles
	profiles.last_used = nil
end

function M.init()
	load_profiles()
	convert_to_rolling_profile_slot()
	local latest = M.get_latest()
	if latest then
		M.set_active(latest)
	end
end

return M