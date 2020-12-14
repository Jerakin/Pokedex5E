local monarch = require "monarch.monarch"
local defsave = require "defsave.defsave"
local md5 = require "utils.md5"
local log = require "utils.log"
local broadcast = require "utils.broadcast"

local M = {}

local profiles = {}
local active_slot
local profile_changing = false
local LATEST_PROFILE_VERSION = 3

-- TODO: Should probably use broadcast, but I couldn't figure out how to get it to work on a non-UI screen
local active_profile_changing_cbs = {}
function M.register_active_profile_changing_cb(cb)
	table.insert(active_profile_changing_cbs, cb)
end
local active_profile_changed_cbs = {}
function M.register_active_profile_changed_cb(cb)
	table.insert(active_profile_changed_cbs, cb)
end
local active_name_changed_cbs = {}
function M.register_active_name_changed_cb(cb)
	table.insert(active_name_changed_cbs, cb)
end

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
	if not profiles.slots[slot] then
		local e = "Can not find slot '" .. tostring(slot) .. "' in profile\n" .. debug.traceback()
		gameanalytics.addErrorEvent {
			severity = "Critical",
			message = e
		}
		log.error(e)
	else
		for key, value in pairs(data) do
			profiles.slots[slot][key] = value
		end
		M.save()
	end
end

function M.delete(slot)
	if M.get_active_slot() then
		M.set_active(nil)
		M.set_active_complete()
	end
	
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
	for i=1,#active_profile_changing_cbs do
		active_profile_changing_cbs[i]()
	end
	
	active_slot = slot
	profiles.last_used = slot
	
	M.save()
end

-- Very hacky but I can't figure out a better way to do this without changing the way profiles
-- work. Currently profiels.gui_script calls set_active, then calls a bunch of load() calls. This
-- means this module isn't actually aware of when it is done switching profiles, because the load
-- is still in progress
function M.set_active_complete()
	for i=1,#active_name_changed_cbs do
		active_name_changed_cbs[i]()
	end
	
	for i=1,#active_profile_changed_cbs do
		active_profile_changed_cbs[i]()
	end
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

			for i=1,#active_name_changed_cbs do
				active_name_changed_cbs[i]()
			end
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

-- HACKY, see caller
local species_variant_cb
function M.register_species_variant_cb(cb)
	species_variant_cb = cb
end

local function upgrade_profiles()
	local version = profiles and profiles.version or 1

	local needs_upgrade = version ~= LATEST_PROFILE_VERSION
	
	if needs_upgrade then
		for i=version,LATEST_PROFILE_VERSION-1 do
			if false then

				-- NOTE: If a new data upgrade is needed, update the above LATEST_PROFILE_VERSION value and add a new block here like so:
				--elseif i == ??? then

			elseif i == 2 then

				if profiles.slots then

					for s=1,#profiles.slots do
						local old_party = profiles.slots[s].party
						local converted_party = {}
						profiles.slots[s].party = converted_party
						if old_party then
							for p=1,#old_party do
								local new_species,new_variant = species_variant_cb(old_party[p])
								table.insert(converted_party, {species=new_species, variant=new_variant})
							end
						end
					end
				end

			elseif i == 1 then
				convert_to_rolling_profile_slot()				
			else
				assert(false, "Unknown profiles data version " .. version)
			end
		end

		profiles.version = LATEST_PROFILE_VERSION
	end
	
	return needs_upgrade
end

local function load_profiles()
	local loaded = defsave.load("profiles")
	profiles = defsave.get("profiles", "profiles")

	if not next(profiles) then
		profiles.version = LATEST_PROFILE_VERSION
	else
		upgrade_profiles()
	end
end

function M.init()
	load_profiles()
	local latest = M.get_latest()
	if latest then
		M.set_active(latest)
	end
end

return M