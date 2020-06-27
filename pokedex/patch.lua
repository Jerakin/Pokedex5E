local log = require "utils.log"

local M = {}

local initialized = false
local patch_data_schema = {}
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

function M.register_patch_schema(key, schema)
	if initialized then
		local e = string.format("Cannot add patch key after initialization: '%s'", tostring(key)) ..  "\n" .. debug.traceback()
		gameanalytics.addErrorEvent {
			severity = "Error",
			message = e
		}
		log.error(e)
		return false
	end
	if patch_data_schema[key] ~= nil then
		local e = string.format("Already tried to register patch key: '%s'", tostring(key)) ..  "\n" .. debug.traceback()
		gameanalytics.addErrorEvent {
			severity = "Error",
			message = e
		}
		log.error(e)
		return false
	end

	patch_data_schema[key] = schema
	
	return true
end

function M.get_patch_data(key, path)
	if patch_data_schema[key] == nil then
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

function M.dump_schema_table(schema, indent)
	local keys_string = ""
	for j=1,#schema.keys do
		if keys_string == "" then
			keys_string = schema.keys[j]
		else
			keys_string = keys_string .. ", " .. schema.keys[j]
		end
	end
	print(indent .. "  keys: [" .. keys_string .. "]")
	if schema.value_type == "array" then
		print(indent .. "  value_type: array")
		print(indent .. "  values: ")
		M.dump_schema_array(schema.values, indent .. "  ")
	elseif schema.value_type == "table" then
		print(indent .. "  value_type: table")
		print(indent .. "  values: ")
		for k,v in pairs(schema.values) do
			print(indent .. "- key: " .. k)
			M.dump_schema_value(v, indent .. "  ")
		end
	elseif schema.value_type == "number" then
		print(indent .. "  value_type: number")
	else
		print(indent .. "  value_type: UNKNOWN")
	end
end

function M.dump_schema_value(value, indent)
	if value.type == "table" then
		print(indent .. "- type: table")
		M.dump_schema_table(value, indent)
	elseif value.type == "string" then
		print(indent .. "- type: string")	
		print(indent .. "- name: " .. value.name)
	else		
		print(indent .. "- type: UNKNOWN")
	end
end

function M.dump_schema_array(schema, indent)
	for i=1,#schema do
		print(indent .. "[" .. i .. "]")
		M.dump_schema_value(schema[i], indent .. "  ")
	end	
end

function M.dump_schema(schema)
	M.dump_schema_value(schema, "")
end

return M