local file = require "utils.file"

local M = {}

local level_data

function M.level_data(level)
	return level_data[tostring(level)]
end

function M.init()
	level_data = file.load_json_from_resource("/assets/datafiles/leveling.json")
end

return M