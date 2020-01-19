local profiles = require "pokedex.profiles"
local storage = require "pokedex.storage"
local json4lua = require "utils.json4lua"

local M = {}

M.SNAPSHOT = nil

local conflictId = nil
local use_saved_games = sys.get_config("gpgs.use_saved_games") == "1"

local SAVE_DATA = {}

local is_ready = false
local time = 0
local changed = false

function M.is_ready()
	return is_ready
end

local function collect_data()
	local data = {}
	
	data.profiles = profiles.get_profiles()
	
	for slot, profile_data in pairs(data.profiles.slots) do
		local file_name = profile_data.file_name
		
		data[file_name] = {}
		data[file_name].storage = storage.get_storage()
		data[file_name].active = storage.get_active()
		data[file_name].counters = storage.get_counters()
		data[file_name].sorting = storage.get_sorting()
	end

	return data
end

function M.load_profile(profile)
	local file_name = profile.file_name

	local storage_data = SAVE_DATA[file_name].storage
	local active_data = SAVE_DATA[file_name].active
	local counters_data = SAVE_DATA[file_name].counters
	local sorting_data = SAVE_DATA[file_name].sorting

	if next(counters_data) == nil then
		counters_data = {caught=0, released=0, seen=0}
	end

	storage.set_storage(storage_data)
	storage.set_active(active_data)
	storage.set_counters(counters_data)
	storage.set_sorting(sorting_data)
end

local function load_data(s_data)
	if s_data == "" then
		return
	end
	SAVE_DATA = json4lua.decode(s_data)

	profiles.set_profile_data(SAVE_DATA.profiles)

	local latest = profiles.get_latest()
	if latest then
		profiles.set_active(latest)
	end
	
	M.load_profile(profiles.get_active())
end


local function open_snapshot()
	gpgs.snapshot_open("pokedex5e", true, gpgs.RESOLUTION_POLICY_LAST_KNOWN_GOOD)
end

local p_
if gpgs then
	p_ = {
		[gpgs.MSG_SIGN_IN] = "gpgs.MSG_SIGN_IN",
		[gpgs.MSG_SILENT_SIGN_IN] = "gpgs.MSG_SILENT_SIGN_IN",
		[gpgs.STATUS_SUCCESS] = "gpgs.STATUS_SUCCESS",
		[gpgs.MSG_SIGN_IN] = "gpgs.MSG_SIGN_IN",
		[gpgs.MSG_SIGN_IN] = "gpgs.MSG_SIGN_IN",
		[gpgs.MSG_SILENT_SIGN_IN] = "gpgs.MSG_SILENT_SIGN_IN",
		[gpgs.MSG_SIGN_OUT] = "gpgs.MSG_SIGN_OUT",
		[gpgs.MSG_SHOW_SNAPSHOTS] = "gpgs.MSG_SHOW_SNAPSHOTS",
		[gpgs.MSG_LOAD_SNAPSHOT] = "gpgs.MSG_LOAD_SNAPSHOT",
		[gpgs.STATUS_SUCCESS] = "gpgs.STATUS_SUCCESS",
		[gpgs.STATUS_FAILED] = "gpgs.STATUS_FAILED",
		[gpgs.STATUS_CREATE_NEW_SAVE] = "gpgs.STATUS_CREATE_NEW_SAVE",
		[gpgs.STATUS_CONFLICT] = "gpgs.STATUS_CONFLICT",
		[gpgs.SNAPSHOT_CURRENT] = "gpgs.SNAPSHOT_CURRENT",
		[gpgs.SNAPSHOT_CONFLICTING] = "gpgs.SNAPSHOT_CONFLICTING",
		[gpgs.ERROR_STATUS_SNAPSHOT_NOT_FOUND] = "gpgs.ERROR_STATUS_SNAPSHOT_NOT_FOUND",
		[gpgs.ERROR_STATUS_SNAPSHOT_CREATION_FAILED] = "gpgs.ERROR_STATUS_SNAPSHOT_CREATION_FAILED",
		[gpgs.ERROR_STATUS_SNAPSHOT_CONTENTS_UNAVAILABLE] = "gpgs.ERROR_STATUS_SNAPSHOT_CONTENTS_UNAVAILABLE",
		[gpgs.ERROR_STATUS_SNAPSHOT_COMMIT_FAILED] = "gpgs.ERROR_STATUS_SNAPSHOT_COMMIT_FAILED",
		[gpgs.ERROR_STATUS_SNAPSHOT_FOLDER_UNAVAILABLE] = "gpgs.ERROR_STATUS_SNAPSHOT_FOLDER_UNAVAILABLE",
		[gpgs.ERROR_STATUS_SNAPSHOT_CONFLICT_MISSING] = "gpgs.ERROR_STATUS_SNAPSHOT_CONFLICT_MISSING"
	}
end

local function resolve_conflict()
	local bytes, error_message = gpgs.snapshot_get_conflicting_data()
	if not bytes then
		print("snapshot_get_conflicting_data ERROR:", error_message)
	else
		print("snapshot_get_conflicting_data:",bytes)
		-- Do something with conflicting data data
	end
end

local function callback(self, message_id, message)
	print("--------")
	print(p_[message_id])
	pprint(message)
	print("--------")
	if message_id == gpgs.MSG_SIGN_IN or message_id == gpgs.MSG_SILENT_SIGN_IN then
		if message.status == gpgs.STATUS_SUCCESS then
			if use_saved_games then
				open_snapshot()
			else 
				is_ready = true
			end
		end
	elseif message_id == gpgs.MSG_SIGN_OUT then

	elseif message_id == gpgs.MSG_LOAD_SNAPSHOT then
		if message.status == gpgs.STATUS_SUCCESS then
			M.load()
		elseif message.status == gpgs.STATUS_CONFLICT then
			conflictId = message.conflictId
			resolve_conflict()
		end
	end
end

function M.init()
	if gpgs then
		gpgs.set_callback(callback)
		gpgs.silent_login()
	end
end

function M.logout()
	if gpgs then
		gpgs.logout()
	end
end

function M.load()
	if gpgs then
		local bytes, error_message = gpgs.snapshot_get_data()
		if not bytes then
			open_snapshot()
		else
			load_data(bytes)
			is_ready = true
		end
	end
end

function M.attempt_sign_in()
	if not gpgs.is_logged_in() then
		gpgs.login()
	end
end

function M.final()
	if gpgs then
		if gpgs.snapshot_is_opened() then
			local s = M.commit()
			if s then
				M.save()
			end
		end
	end
end

local function _commit()
	local data = collect_data()
	local success, error_message = gpgs.snapshot_set_data(json4lua.encode(data))
	if success then
		print("COMMIT IS SUCCESSFULL")
		changed = false
	else
		open_snapshot()
		print("snapshot_set_data ERROR:", error_message)
	end
	return success
end

function M.commit()
	changed = true
end

function M.update(dt)
	if changed then
		time = time + dt
		if time > 5 then
			time = 0
			_commit()
		end
	end	
end

function M.save()
	print("commit and close")
	if changed then
		_commit()
	end
	gpgs.snapshot_commit_and_close()
end

function M.delete(file_name)
	SAVE_DATA[file_name] = nil
end

return M