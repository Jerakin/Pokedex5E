local log = require "utils.log"
local utils = require "utils.utils"
local defsave = require "defsave.defsave"
local json = require "defsave.json"
local settings = require "pokedex.settings"
local log = require "utils.log"
local flow = require "utils.flow"
local file = require "utils.file"

local M = {}

M.is_busy = false

local initialized = false
local patch_data
local patch_data_compiled

local os_sep = package.config:sub(1, 1)
local patch_file = "patch"
local patches_key = "patches"
local patch_dir

local function file_exists(name)
	local f = io.open(name, "r")
	return f ~= nil and io.close(f)
end

local function compile_patch_data()
	patch_data_compiled = {}
	for i=1,#patch_data do
		if patch_data[i].enabled and patch_data[i].data ~= nil then
			-- first .data here is the download, which includes meta information about the patch like the name and description.
			-- second .data here is the actual data, like what things should be patched and how
			utils.deep_merge_into(patch_data_compiled, patch_data[i].data.data)
		end
	end

	-- TODO: Some sort of event for everything to key off if they need to reset caches or something for new patch data
end

local function download_all_patches()
	return flow.start(function()		
		for i=1,#patch_data do
			local this_patch_data = patch_data[i]
			local num_to_download = 0
			if this_patch_data.url ~= nil then
				num_to_download = num_to_download + 1
				http.request(this_patch_data.url, "GET", function(self, id, res)
					if res.status == 200 or res.status == 304 then
						this_patch_data.data = json.decode(res.response)	
						this_patch_data.last_download_success = os.time()
						this_patch_data.error = nil
					else
						this_patch_data.error = tostring(res.status) .. ": " .. tostring(res.response)
					end
					this_patch_data.last_download_attempt = os.time()
					num_to_download = num_to_download - 1
				end)
			end
			flow.until_true(function() return num_to_download == 0 end)
		end
	end)
end
	
function M.init()
	if not initialized then
		M.is_busy = true
		flow.start(function()				
			patch_dir = defsave.get_file_path("") .. "patches" .. os_sep

			defsave.load(patch_file)
			patch_data =  defsave.get(patch_file, patches_key) or {}

			-- TEMP
			if next(patch_data) == nil then
				patch_data =
				{
					{
						enabled = true,
						url = "https://raw.githubusercontent.com/magroader/Pokemon5EPatchExample/master/nature_rename.json",
					},
					{
						enabled = true,
						url = "https://raw.githubusercontent.com/magroader/Pokemon5EPatchExample/master/speed_adjust.json",
					},
					{
						enabled = false,
						url = "https://raw.githubusercontent.com/magroader/Pokemon5EPatchExample/master/speed_adjust.json",
					},
					{
						enabled = false,
						url = "https://raw.githubusercontent.com/magroader/Pokemon5EPatchExample/master/speed_adjust.json",
					},
					{
						enabled = false,
						url = "https://raw.githubusercontent.com/magroader/Pokemon5EPatchExample/master/speed_adjust.json",
					},
					{
						enabled = false,
						url = "https://raw.githubusercontent.com/magroader/Pokemon5EPatchExample/master/speed_adjust.json",
					},
					{
						enabled = false,
						url = "https://raw.githubusercontent.com/magroader/Pokemon5EPatchExample/master/speed_adjust.json",
					},
					{
						enabled = false,
						url = "https://raw.githubusercontent.com/magroader/Pokemon5EPatchExample/master/speed_adjust.json",
					},
					{
						enabled = false,
						url = "https://raw.githubusercontent.com/magroader/Pokemon5EPatchExample/master/speed_adjust.json",
					},
				}
				download_all_patches()
				defsave.set(patch_file, patches_key, patch_data)
				defsave.save(patch_file)
			end
			-- END TEMP
			
			compile_patch_data()

			M.is_busy = false
			initialized = true
		end)
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

function M.get_all_patch_data_details()
	local ret = {}
	
	for i=1, #patch_data do
		local this_details = {}
		table.insert(ret, this_details)
		
		local this_data = patch_data[i]
		this_details.url = this_data.url
		this_details.last_download_success = this_data.last_download_success
		this_details.enabled = this_data.enabled
		if this_data.data ~= nil then
			this_details.name = this_data.data.name
			this_details.description = this_data.data.description
			this_details.author = this_data.data.author
		end		
	end

	return ret
end

return M