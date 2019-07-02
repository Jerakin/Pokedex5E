local defsave = require "defsave.defsave"
local zzlib = require "utils.zzlib"
local flow = require "utils.flow"
local ufile = require "utils.file"
local settings = require "pokedex.settings"
local md5 = require "utils.md5"
local log = require "utils.log"
local monarch = require "monarch.monarch"

local M = {}

local downloading = false
local unpacking = false

-- Supported files
M.abilities = nil
M.evolve = nil
M.exp_grid = nil
M.feats = nil
M.habitat = nil
M.items = nil
M.leveling = nil
M.move_machines = nil
M.moves = nil
M.pokedex_extra = nil
M.pokemon_number = nil
M.pokemon_order = nil
M.pokemon_types = nil
M.pokemon = nil
M.trainer_classes_list = nil
M.trainer_classes = nil

local extra_json_files = {
	abilities = "abilities.json",
	evolve = "evolve.json",
	exp_grid = "exp_grid.json",
	feats = "feats.json",
	habitat = "habitat.json",
	items = "items.json",
	leveling = "leveling.json",
	move_machines = "move_machines.json",
	moves = "moves.json",
	pokedex_extra = "pokedex_extra.json",
	pokemon_number = "pokemon_number.json",
	pokemon_order = "pokemon_order.json",
	pokemon_types = "pokemon_types.json",
	pokemon = "pokemon.json",
	trainer_classes_list = "trainer_classes_list.json",
	trainer_classes = "trainer_classes.json"
}


M.PACKAGE_NAME = nil
M.APP_ROOT = nil
M.success = false
local os_sep = package.config:sub(1, 1)
local resource_path

local function get_checksum(res)
	local m = md5.new()
	m:update(tostring(res))
	return md5.tohex(m:finish())
end

local function download(url)
	http.request(url, "GET", function(self, id, res)
		print(res.status)
		
		if res.status == 302 then
			-- 302 Found (Redirect)
			local url = string.gsub(res.response, '<html><body>You are being <a href="', "")
			url = string.gsub(url, '">redirected</a>.</body></html>', "")
			download(url)
		elseif res.status == 200 or res.status == 304 then
			-- 200 OK or 304 Not Modified
			local file, err = io.open(resource_path, "wb")

			if file then
				file:write(res.response)
				file:close()
				for repo, branch in string.gmatch(url, "https://codeload.github.com/%w+/(.+)/zip/(.+)") do
					settings.set("fakemon_package", repo .. "-" .. branch) 
				end
				M.unpack()
				M.success = true
			else
				local e = "Error while opening file\n" .. err
				log.warn(e)
				M.success = false
			end
			downloading = false
		else
			monarch.show("info", nil, {text="\nInvalid Package URL \n(STATUS: " .. res.status .. ")"})
		end
	end)
end

function M.download(url)
	downloading = true
	settings.set("fakemon_url", url)
	download(url)
end

function M.unpack()
	log.info("Started unpacking " .. resource_path)
	
	local file = io.open(resource_path, "rb")
	local input = file:read("*all")
	local output, err = zzlib.unzip_archive(input, M.APP_ROOT)
	if err then
		log.warning(err)
		M.success = false
	end
	log.info("Unpacking finished")
end

local function file_exists(name)
	local f = io.open(name, "r")
	return f ~= nil and io.close(f)
end

function M.is_ready()
	return not downloading and not unpacking
end

function M.init()
	M.APP_ROOT = defsave.get_file_path("")
	M.PACKAGE_NAME = settings.get("fakemon_package")
	resource_path = defsave.get_file_path("resource.zip")
	M.load()
end

function M.load()
	flow.start(function()
		if M.PACKAGE_NAME then
			log.info("Using package " .. M.PACKAGE_NAME)
			local valid = false
			for n, file_name in pairs(extra_json_files) do
				local package_path = M.APP_ROOT .. M.PACKAGE_NAME .. os_sep .. file_name
				if file_exists(package_path) then
					valid = true
					log.info("Found and loaded file " .. file_name)
					M[n] = ufile.load_file(package_path)
				end
			end
			if not valid then
				timer.delay(2, false, function()
					monarch.show("info", nil, {text="\nInvalid Fakemon Package"})
				end)
			end
		end
	end)
end


return M