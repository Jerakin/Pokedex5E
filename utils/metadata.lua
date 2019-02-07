local defsave = require "defsave.defsave"

local M = {}
local loaded_data = {}

local filename = "metadata"

local function collect()
	local data = {}
	local engine = sys.get_engine_info()
	data.engine_version = engine.version
	data.app_version = sys.get_config("project.version")
	data.time = socket.gettime()
	return data
end

function M.get(key)
	return loaded_data[key]
end

function M.save()
	local data = collect()
	defsave.set(filename, "data", data)
	defsave.save(filename)
end
	
function M.load()
	defsave.load(filename)
	loaded_data = defsave.get(filename, "data")
end

function M.get_data()
	return loaded_data
end

return M