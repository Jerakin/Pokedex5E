local log = require "utils.log"

local M = {}

local initialized = false
local patch_data_keys = {}
local patch_data = {}

function M.init()
	if not initialized then
		initialized = true
	end

	-- TEMP, example data that could be loaded up
	table.insert(patch_data, {
		name = "Patch 1",
		data = {
			Nature = {
				Dumb = {
					DisplayName = "Silly"
				}
			}
		}
	})
	
	table.insert(patch_data, {
		name = "Patch 2",
		data = {
			Nature = {
				Dumb = {
					DisplayName = "Quiet"
				}
			}
		}
	})
end

function M.register_patch_key(key, schema)
	if initialized then
		local e = string.format("Cannot add patch key after initialization: '%s'", tostring(key)) ..  "\n" .. debug.traceback()
		gameanalytics.addErrorEvent {
			severity = "Error",
			message = e
		}
		log.error(e)
		return false
	end
	if patch_data_keys[key] ~= nil then
		local e = string.format("Already tried to register patch key: '%s'", tostring(key)) ..  "\n" .. debug.traceback()
		gameanalytics.addErrorEvent {
			severity = "Error",
			message = e
		}
		log.error(e)
		return false
	end

	patch_data_keys[key] = true
	
	return true
end

function M.get_patch_data(key, path)
	if patch_data_keys[key] == nil then
		local e = string.format("Tried to get patch data for a key that was not registered: '%s'", tostring(key)) ..  "\n" .. debug.traceback()
		gameanalytics.addErrorEvent {
			severity = "Error",
			message = e
		}
		log.error(e)
		return nil		
	end
	
	for i=#patch_data, 1, -1 do
		
		local current = patch_data[i].data[key]
		for j=1,#path do
			if current == nil then
				break
			end
			current = current[path[j]]
		end
		if current ~= nil then
			return current
		end
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