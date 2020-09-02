local defsave = require "defsave.defsave"
local settings = require "pokedex.settings"
local log = require "utils.log"
local flow = require "utils.flow"
local defsave = require "defsave.defsave"
local zzlib = require "utils.zzlib"
local file = require "utils.file"

local M = {}
if sys.get_engine_info().is_debug then
	print("Using FakemonPackages/develop")
	GITHUB_URL = "https://raw.githubusercontent.com/Jerakin/FakemonPackages/develop"
else
	GITHUB_URL = "https://raw.githubusercontent.com/Jerakin/FakemonPackages/master"
end

M.INDEX = nil
M.BUSY = false

M.DATA = nil

local RESOURCE_PATH
M.UNZIP_PATH = nil
M.LOCAL_INDEX = nil
local os_sep = package.config:sub(1, 1)

function M.init()
	RESOURCE_PATH = defsave.get_file_path("resource.zip")
	M.UNZIP_PATH = defsave.get_file_path("") .. "package" .. os_sep
	M.load_package()
end


local function get_package_entry(package)
	for _, data in pairs(M.INDEX) do
		if data.name == package then
			return data
		end
	end
end


local function file_exists(name)
	local f = io.open(name, "r")
	return f ~= nil and io.close(f)
end

--- Check if a file or directory exists in this path
function exists(file)
	local ok, err, code = os.rename(file, file)
	if not ok then
		if code == 13 then
			-- Permission denied, but it exists
			return true
		end
	end
	return ok, err
end

--- Check if a directory exists in this path
function isdir(path)
	-- "/" works on both Unix and Windows
	return exists(path.."/")
end

function M.load_package()
	M.BUSY = true
	flow.start(function()
		local package_path = M.UNZIP_PATH .. "data.json"
		local index_path = M.UNZIP_PATH .. "index.json"
		if file_exists(package_path) and file_exists(index_path) then
			log.info("Found and loaded file " .. package_path)
			M.DATA = file.load_file(package_path)
			log.info("Found and loaded file " .. index_path)
			M.LOCAL_INDEX = file.load_file(index_path)
		else
			log.info("No Fakemon Package found")
		end
		M.BUSY = false
	end)
end

function M.unpack()
	M.BUSY = true
	log.info("Started unpacking " .. RESOURCE_PATH)

	local file = io.open(RESOURCE_PATH, "rb")
	local input = file:read("*all")

	flow.start(function() 
		local exists, _ = lfs.exists(M.UNZIP_PATH)
		if exists then
			lfs.rmdirs(M.UNZIP_PATH)
			flow.frames(5)
			lfs.mkdir(M.UNZIP_PATH)
		else
			lfs.mkdir(M.UNZIP_PATH)
		end

		local output, err = zzlib.unzip_archive(input, M.UNZIP_PATH)
		if err then
			local e = "Fakemon:UnpackZIP:" .. err
			log.error(e)

			gameanalytics.addErrorEvent {
				severity = "Error",
				message = e
			}
		end
		log.info("Unpacking finished")
	end)
	M.BUSY = false
end

function M.load_index()
	M.BUSY = true
	local index_url = GITHUB_URL .. "/" .. "index.json"
	http.request(index_url, "GET", function(self, id, res)
		if res.status == 200 or res.status == 304 then
			M.INDEX = json.decode(res.response)
			M.BUSY = false
		else
			M.INDEX = nil
			gameanalytics.addErrorEvent {
				severity = "Warning",
				message = "Fakemon:LoadIndex:HTTP:" .. res.status 
			}
			log.info("BAD STATUS:" .. res.status)
			log.info(res.response)
		end
	end)
end

function M.remove_package()
	M.BUSY = true
	flow.start(function() 
		local exists, _ = lfs.exists(M.UNZIP_PATH)
		if exists then
			lfs.rmdirs(M.UNZIP_PATH)
		end
		M.BUSY = false
	end)
end

function M.download_package(package)
	M.BUSY = true
	log.info("STARTED DOWNLOAD")
	local data = get_package_entry(package)
	settings.set("package", data)
	local package_url = GITHUB_URL .. "/" .. string.gsub(data.path, "%s+", '%%20')

	http.request(package_url, "GET", function(self, id, res)
		if res.status == 200 or res.status == 304 then
			log.info("DOWNLOADING: " .. data.path)
			local file, err = io.open(RESOURCE_PATH, "wb")

			if file then
				file:write(res.response)
				file:close()
			else
				local e = "Fakemon:File:\n" .. err
				log.warn(e)
				gameanalytics.addErrorEvent {
					severity = "Warning",
					message =  e
				}
			end
			log.info("FINISHED DOWNLOAD")
		else
			local e = "Fakemon:DownloadPackage:HTTP:" .. res.status  .. " URL: " .. package_url
			log.warn(e)
			gameanalytics.addErrorEvent {
				severity = "Warning",
				message = e
			}
		end
		M.BUSY = false
	end)
end

return M