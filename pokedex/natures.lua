local file = require "utils.file"

local M = {}

local initialized = false
local natures

local function list()
	local temp_list = {}
	local total = 1
	for name, _ in pairs(natures) do
		total = total + 1
		table.insert(temp_list, name)
	end
	return temp_list, total
end

function M.is_nature(nature)
	return natures[nature] and true or false
end

function M.get_nature_attributes(nature)
	return natures[nature]
end

function M.get_AC(nature)
	return natures["AC"] or 0
end

function M.init()
	if not initialized then
		natures = file.load_json_from_resource("/assets/datafiles/natures.json")
		M.list, M.total = list()
		initialized = true
	end
end


return M