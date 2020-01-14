local defsave = require "defsave.defsave"
local json = require "defsave.json"

local M = {}

M.SNAPSHOT = nil

local conflictId = nil
local use_saved_games = sys.get_config("gpgs.use_saved_games") == "1"
local not_saved_data = nil

local is_ready = false

function M.is_ready()
	if gpgs then
		return is_ready
	end
	return true
end

local function collect_data()
	local data = {}
	defsave.load("profiles")
	local profiles = defsave.get("profiles", "profiles")
	data.profiles = profiles
	for slot, profile_data in pairs(profiles.slots) do
		local file_name = profile_data.name
		if not defsave.is_loaded(file_name) then
			local loaded = defsave.load(file_name)
			data[profile_data.name] = {}

			data[profile_data.name].storage = defsave.get(file_name, "storage")
			data[profile_data.name].active = defsave.get(file_name, "active")
			data[profile_data.name].counters = defsave.get(file_name, "counters")
			data[profile_data.name].sorting = defsave.get(file_name, "sorting")
		end
	end
	return data
end



local function extract_data(s_data)
	print("--EXTRACT--")
	pprint(s_data)
	print("------")
	if s_data == "" then
		return
	end
	local data = json.decode(s_data)
	defsave.load("profiles")
	defsave.set("profiles", "profiles", data.profiles)
	defsave.save("profiles")

	for slot, profile_data in pairs(data.slots) do
		file_name = profile_data.name
		defsave.load(file_name)
		defsave.set(file_name, "storage", data.slots[slot].storage)
		defsave.set(file_name, "active", data.slots[slot].active)
		defsave.set(file_name, "counters", data.slots[slot].counters)
		defsave.set(file_name, "sorting", data.slots[slot].sorting)
		defsave.save(file_name)
	end
	defsave.save_all(true)
end


local function open_snapshot()
	gpgs.snapshot_open("pokedex5e", true, gpgs.RESOLUTION_POLICY_MOST_RECENTLY_MODIFIED)
end

local function callback(self, message_id, message)
	print("---------")
	print(message_id)
	pprint(message)
	print("---------")
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
		if message.status == gpgs.STATUS_CONFLICT then
			print("CONFLICT!?!?")
		elseif message.status == gpgs.STATUS_FAILED then
			print("FAILED!?!?")
			is_ready = true
		elseif message.status == gpgs.STATUS_SUCCESS then
			M.get_data()
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

function M.get_data()
	if gpgs then
		local bytes, error_message = gpgs.snapshot_get_data()
		if not bytes then
			print("snapshot_get_data ERROR:", error_message)
		else
			extract_data(bytes)
			is_ready = true
		end
	end
end

function M.is_logged_in()
	if gpgs then
		gpgs.is_logged_in()
	end
end

function M.attempt_sign_in()
	if gpgs then
		if not M.is_logged_in() then
			gpgs.login()

		else
			M.final()
		end
	end
end

function M.final()
	if gpgs then
		if gpgs.snapshot_is_opened() then
			local s = M.set_data()
			if s then
				M.save_data()
			end
		end
	end
end

function M.set_data()
	if gpgs then
		local data = collect_data()
		local success, error_message = gpgs.snapshot_set_data(json.encode(data))
		if success then
			print("COMMIT IS SUCCESSFULL")
		else
			print("snapshot_set_data ERROR:", error_message)
		end
		return success
	end
end


function M.save_data(data)
	if gpgs then
		gpgs.snapshot_commit_and_close()
	end
end


return M