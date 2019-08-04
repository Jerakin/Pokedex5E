local defsave = require "defsave.defsave"
local settings = require "pokedex.settings"
local log = require "utils.log"
local flow = require "utils.flow"
local defsave = require "defsave.defsave"
local zzlib = require "utils.zzlib"
local file = require "utils.file"

local M = {}

GITHUB_URL = "https://raw.githubusercontent.com/Jerakin/FakemonPackages/master"

M.INDEX = nil
M.BUSY = false

M.DATA = {}

local RESOURCE_PATH
local UNZIP_PATH

local os_sep = package.config:sub(1, 1)

function M.init()
	RESOURCE_PATH = defsave.get_file_path("resource.zip")
	UNZIP_PATH = defsave.get_file_path("")
end

local function get_package_entry(package)
	for _, data in pairs(M.INDEX) do
		if data.name == package then
			return data.path
		end
	end
end


local function file_exists(name)
	local f = io.open(name, "r")
	return f ~= nil and io.close(f)
end

function M.load_package()
	local info = settings.get("package")
	M.BUSY = true
	flow.start(function()
		local valid = false
		local package_path = UNZIP_PATH .. "data.json"
		if file_exists(package_path) then
			valid = true
			log.info("Found and loaded file " .. package_path)
			M.DATA = file.load_file(package_path)
		end
		if not valid then
			print("INVALID")
		end
		M.BUSY = false
	end)
end

function M.unpack()
	M.BUSY = true
	log.info("Started unpacking " .. RESOURCE_PATH)

	local file = io.open(RESOURCE_PATH, "rb")
	local input = file:read("*all")

	local output, err = zzlib.unzip_archive(input, UNZIP_PATH)
	if err then
		log.warning(err)
	end
	log.info("Unpacking finished")
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
			print("BAD STATUS:", res.status)
			print(res.response)
		end

	end)
end

function M.download_package(package)
	M.BUSY = true
	log.info("STARTED DOWNLOAD")
	local data = get_package_entry(package)
	settings.set("package", data)

	local package_url = GITHUB_URL .. "/" .. "packages/baby%20birds.fkmn"

	http.request(package_url, "GET", function(self, id, res)
		if res.status == 200 or res.status == 304 then
			log.info("DOWNLOADING")
			local file, err = io.open(RESOURCE_PATH, "wb")

			if file then
				file:write(res.response)
				file:close()
			else
				local e = "Error while opening file\n" .. err
				log.warn(e)
			end
			log.info("FINISHED DOWNLOAD")
		else
			print("BAD STATUS:", res.status)
		end
		M.BUSY = false
	end)
end

return M