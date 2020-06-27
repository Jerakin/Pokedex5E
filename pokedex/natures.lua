local file = require "utils.file"
local log = require "utils.log"
local fakemon = require "fakemon.fakemon"
local patch = require "pokedex.patch"

local M = {}

local initialized = false
local natures
local patch_key = "Nature"

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

		if fakemon.DATA and fakemon.DATA["natures.json"] then
			for name, data in pairs(fakemon.DATA["natures.json"]) do
				natures[name] = data
			end
		end
		M.list, M.total = list()
		
		local nature_keys = {}
		local modifier_keys_seen = {}
		local modifier_keys = {}
		for n_k, n_v in pairs(natures) do
			table.insert(nature_keys, n_k)
			for a_k,_ in pairs(n_v) do
				if modifier_keys_seen[a_k] == nil then
					modifier_keys_seen[a_k] = true
					table.insert(modifier_keys, a_k)
				end
			end
		end
		table.sort(modifier_keys)

		local schema =
		{
			type = "table",
			keys = nature_keys,
			value_type = "table",
			values =
			{
				DisplayName = 
				{
					type = "string",
					name = "Display Name",
				},
				Attributes =
				{
					type = "table",
					keys = modifier_keys,
					value_type = "number",
				},
			},
		}

		print("Nature Schema:")
		patch.dump_schema(schema)
		
		initialized = true
	end
end

return M