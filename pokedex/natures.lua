local file = require "utils.file"

local M = {}

local initialized = false

local function list()
	local temp_list = {}
	local total = 1
	for name, _ in pairs(M.natures) do
		total = total + 1
		table.insert(temp_list, name)
	end
	return temp_list, total
end

function M.nature_data(nature)
	return M.natures[nature]
end

function M.is_nature(nature)
	return M.natures[nature] and true or false
end

function M.get_nature_attributes(nature)
	local attributes = {}
	local nature_data = M.nature_data(nature)
	attributes.STR = nature_data.STR or 0
	attributes.DEX = nature_data.DEX or 0
	attributes.CON = nature_data.CON or 0
	attributes.INT = nature_data.INT or 0
	attributes.WIS = nature_data.WIS or 0
	attributes.CHA = nature_data.CHA or 0
	attributes.AC = nature_data.AC or 0
	
	return attributes
end

function M.init()
	if not initialized then
		M.natures = file.load_json_from_resource("/assets/datafiles/natures.json")
		M.list, M.total = list()
		initialized = true
	end
end


return M