local file = require "utils.file"

local M = {}


local function list()
	local temp_list = {}
	local total = 1
	for name, _ in pairs(M.natures) do
		total = total + 1
		table.insert(temp_list, name)
	end
	return temp_list, total
end

function M.init()
	M.natures = file.load_json_from_resource("/assets/datafiles/natures.json")
	M.list, M.total = list()
end


return M