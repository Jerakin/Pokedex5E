local defsave = require "defsave.defsave"

local M = {}

local function files()
	local file_names = {"settings", "profiles"}
	local file_paths = {}
	local loaded = defsave.load("profiles")
	if loaded then
		profiles = defsave.get("profiles", "profiles")
		if next(profiles) ~= nil then
			for _, profile in pairs(profiles.slots) do
				table.insert(file_names, profile.file_name)
			end

			for _, file_name in pairs(file_names) do
				file_paths[file_name] = defsave.get_file_path(file_name)
			end

			return file_paths
		end
	end
end

local function backup_file()
	local files_to_backup = files()
	if files_to_backup == nil then
		return
	end
	local data = {}

	for name, path in pairs(files_to_backup) do 
		data[name] = sys.load(path)
	end
	return data
end


function M.save_backup()
	local json_data = backup_file()
	if json_data ~= nil then
		local file_path = defsave.get_file_path("backup.json")
		sys.save(file_path, json_data)
		share.file(file_path)
	end
end


function M.load_backup(file_path)
	local data = sys.load(file_path)
	for file_name, file_data in pairs(data) do
		local save_file = sys.get_save_file(defsave.appname, file_name)
		sys.save(save_file, file_data)
	end
end


return M