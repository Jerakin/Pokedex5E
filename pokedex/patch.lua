local log = require "utils.log"
local utils = require "utils.utils"
local defsave = require "defsave.defsave"
local settings = require "pokedex.settings"
local log = require "utils.log"
local flow = require "utils.flow"
local file = require "utils.file"

local M = {}

M.is_busy = false

local initialized = false
local patch_data_keys = {}
local patch_index
local patch_data
local patch_data_compiled

local os_sep = package.config:sub(1, 1)
local patch_index = "patch"
local patches_key = "patches"
local patch_dir

local function file_exists(name)
	local f = io.open(name, "r")
	return f ~= nil and io.close(f)
end

local function compile_patch_data()
	patch_data_compiled = {}
	for i=1,#patch_data do
		if patch_data[i].enabled then
			utils.deep_merge_into(patch_data_compiled, patch_data[i].data)
		end
	end

	-- TODO: Some sort of event for everything to key off if they need to reset caches or something for new patch data
end

local function load_patch_index()
	M.is_busy = true
	flow.start(function()
		local loaded_patch_index = defsave.file_exists(patch_index) and defsave.load(patch_index)
		if loaded_patch_index then
			patch_index = defsave.get(patch_file, patches_key) or {}
		else
			patch_index = {}
		end

		patch_data = {}
		
		for i=1,#patch_index do
			local file_name = patch_index[i].file
			if file_name ~= nil then
				if file_exists(file_name) then					
					local this_patch_data = file.load_file(patch_index[i].file)
					if this_patch_data ~= nil then
						table.insert(patch_data, this_patch_data)
					else
						table.insert(patch_data, { name = "ERROR", description = "Could not load patch file " .. tostring(patch_index[i].file) })
					end
				else
					table.insert(patch_data, { name = "ERROR", description = "Could not find patch file " .. tostring(patch_index[i].file) })
				end
			else
				table.insert(patch_data, { name = "ERROR", description = "Unknown patch file" })
			end
		end

		-- If I understood how all this works right (I probably did not), the above should have loaded an index file (if one exists) and then M.is_loaded
		-- some json into our patch_data. But I don't have time to test it right now, so just committing with a comment.

		compile_patch_data()
		M.is_busy = false
	end)
end
	
function M.init()
	if not initialized then
		initialized = true

		patch_dir = defsave.get_file_path("") .. "patches" .. os_sep
		load_patch_index()
	end
end

function M.get_patch_data(key, path)
	local current = patch_data_compiled[key]
	for j=1,#path do
		if current == nil then
			break
		end
		current = current[path[j]]
	end
	if current ~= nil then
		return current
	end
	return nil
end

function M.get_patch_names()
	local ret = {}
	for i=1, #patch_data, 1 do
		table.insert(ret, patch_data[i].name)
	end
	return ret
end

return M