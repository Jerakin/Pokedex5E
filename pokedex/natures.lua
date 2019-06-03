local file = require "utils.file"
local log = require "utils.log"
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
	table.sort(temp_list)
	table.remove(temp_list, 15)
	
	table.insert(temp_list, 1, "No Nature")
	return temp_list, total
end

function M.is_nature(nature)
	return M.get_nature_attributes(nature) and true or false
end

function M.get_nature_attributes(nature)
	if natures[nature] then
		return natures[nature]
	end
	return natures["No Nature"]
end

function M.get_AC(nature)
	return M.get_nature_attributes(nature)["AC"] or 0
end

function M.init()
	if not initialized then
		natures = file.load_json_from_resource("/assets/datafiles/natures.json")
		M.list, M.total = list()
		initialized = true
	end
end


return M