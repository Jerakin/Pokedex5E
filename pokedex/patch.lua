local log = require "utils.log"
local utils = require "utils.utils"

local M = {}

local initialized = false
local patch_data_keys = {}
local patch_data = {}
local patch_data_compiled

local function compile_patch_data()
	patch_data_compiled = {}
	for i=1,#patch_data do
		if patch_data[i].enabled then
			utils.deep_merge_into(patch_data_compiled, patch_data[i].data)
		end
	end

	-- TODO: Some sort of event for everything to key off if they need to reset caches or something for new patch data
end
	
function M.init()
	if not initialized then
		initialized = true
	end

	-- TEMP, example data that could be loaded up
	table.insert(patch_data, {
		name = "Patch 1",
		enabled = false,
		data = {}
	})
	table.insert(patch_data, {
		name = "Patch 2",
		enabled = true,
		data = {
			Nature = {
				Dumb = {
					DisplayName = "Silly",
				}
			},
			Pokedex = {
				Electrode = {
					WSp = 90,
				},
			},
		}
	})
	
	table.insert(patch_data, {
		name = "Patch 3",
		enabled = true,
		data = {
			Nature = {
				Dumb = {
					DisplayName = "Quiet",
				}
			},
			Pokedex = {
				Electrode = {
					["Climbing Speed"] = 30,
				},
			},
		}
	})

	table.insert(patch_data, {
		name = "Patch 4",
		enabled = false,
		data = {
			Nature = {
				Dumb = {
					DisplayName = "Bananas",
				}
			}
		}
	})

	compile_patch_data()
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