local file = require "utils.file"
local utils = require "utils.utils"
local log = require "utils.log"

local M = {}

local initialized = false
local items = {}
local list = {}

function M.get_list()
	return list
end

local function create_list()
	for name, desc in pairs(items) do
		table.insert(list, name)
	end
end

function M.init()
	if not initialized then
		items = file.load_json_from_resource("/assets/datafiles/items.json")
		initialized = true
		create_list()
	end
end

return M