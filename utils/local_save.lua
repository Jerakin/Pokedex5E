local defsave = require "defsave.defsave"
local profiles = require "pokedex.profiles"
local storage = require "pokedex.storage"

local M = {}

local time = 0

local changed = false

local _ready = false

function M.final()
	M.save()
end

function M.is_ready()
	return _ready
end

function M.save()
	defsave.set("profiles", "profiles", profiles.get_profiles())
	defsave.save("profiles")
	
	if profiles.get_active_slot() then
		local profile = profiles.get_active_file_name()
		defsave.set(profile, "storage", storage.get_storage())
		defsave.set(profile, "active", storage.get_active())
		defsave.set(profile, "counters", storage.get_counters())
		defsave.set(profile, "sorting", storage.get_sorting())
		defsave.save(profile)
	end

	changed = false
end

function M.delete(file_name)
	defsave.delete(f_name)
end

function M.load_profile(profile)
	local file_name = profile.file_name

	if not defsave.is_loaded(file_name) then
		defsave.load(file_name)
	end

	storage_data = defsave.get(file_name, "storage")
	active_data = defsave.get(file_name, "active")
	counters_data = defsave.get(file_name, "counters")
	sorting_data = defsave.get(file_name, "sorting")

	if next(counters_data) == nil then
		counters_data = {caught=0, released=0, seen=0}
	end
	
	storage.set_storage(storage_data)
	storage.set_active(active_data)
	storage.set_counters(counters_data)
	storage.set_sorting(sorting_data)
end

function M.load()
	if not defsave.is_loaded("profiles") then
		defsave.load("profiles")
	end
	
	local profiles_data = defsave.get("profiles", "profiles")
	
	if not profiles_data then
		return
	end
	profiles.set_profile_data(profiles_data)

	local latest = profiles.get_latest()
	if latest then
		profiles.set_active(latest)
	end


	M.load_profile(profiles.get_active())
	
	-- Default counters

	_ready = true
end

function M.commit()
	changed = true
end

function M.update(dt)
	if changed then
		time = time + dt
		if time > 10 then
			time = 0
			M.save()
		end
	end	
end

function M.init()
	-- Keep
end


return M