local monarch = require "monarch.monarch"
local defsave = require "defsave.defsave"
local md5 = require "utils.md5"
local log = require "utils.log"
local broadcast = require "utils.broadcast"
local messages = require "utils.messages"
local signal = require "utils.signal"

local storage = require "pokedex.storage"
local trainer = require "pokedex.trainer"

local M = {}

M.SIGNAL_AFTER_PROFILE_CHANGE = signal.create("change_profile")
M.SIGNAL_BEFORE_PROFILE_CHANGE = signal.create("change_profile_success")

local profiles = {}
local active_slot
local profile_changing = false


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
	M.SIGNAL_BEFORE_PROFILE_CHANGE.trigger()
	active_slot = slot
	profiles.last_used = slot
	M.SIGNAL_AFTER_PROFILE_CHANGE.trigger()
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

			M.SIGNAL_AFTER_PROFILE_CHANGE.trigger()
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
	
local function on_party_updated(message)
	M.set_party(message.party)
end

local function on_counters_updated(message)
	M.update(M.get_active_slot(), message.counters)
end

--------- Save Other
local function save_storage()
	local profile_name = M.get_active_file_name()
	local storage_data = storage.get_data()
	defsave.set(profile_name, "storage_data", storage_data)
	defsave.save(profile_name)
end

local function save_trainer()
	local file_name = M.get_active_file_name()
	local trainer_data = trainer.get_data()
	defsave.set(file_name, "trainer", trainer_data)
	defsave.save(file_name)
end

local function load_profile_data(data_name)
	local file_name = M.get_active_file_name()
	local file_loaded = true
	local loaded_data
	if file_name and not defsave.is_loaded(file_name) then
		file_loaded = defsave.load(file_name)
	end
	if file_loaded then
		loaded_data = defsave.get(file_name, "storage_data")
	end
	return loaded_data
end

local function load_storage()
	local loaded_data = load_profile_data("storage_data")
	local requires_save = storage.load(loaded_data)
	if requires_save then
		save_storage()
	end
end


local function load_trainer()
	local loaded_data = load_profile_data("trainer")
	trainer.load(loaded_data)
end


--------------
function M.init()
	broadcast.register(messages.PARTY_UPDATED, on_party_updated)
	broadcast.register(messages.COUNTERS_UPDATED, on_counters_updated)
	broadcast.register(messages.SAVE_POKEMON, save_storage)
	broadcast.register(messages.SAVE_TRAINER, save_trainer)

	M.SIGNAL_BEFORE_PROFILE_CHANGE.add(save_storage)
	M.SIGNAL_BEFORE_PROFILE_CHANGE.add(save_trainer)
	M.SIGNAL_BEFORE_PROFILE_CHANGE.add(M.save)
	
	M.SIGNAL_AFTER_PROFILE_CHANGE.add(load_storage)
	M.SIGNAL_AFTER_PROFILE_CHANGE.add(load_trainer)
	
	load_profiles()
	convert_to_rolling_profile_slot()
	local latest = M.get_latest()
	if latest then
		M.set_active(latest)
	end
end
return M