local ljson = require "defsave.json"
local storage = require "pokedex.storage"
local url = require "utils.url"
local notify = require "utils.notify"
local monarch = require "monarch.monarch"
local dex = require "pokedex.dex"
local pokedex = require "pokedex.pokedex"
local statuses = require "pokedex.statuses"

local M = {}

local function load_json(j)
	local json_data = nil
	-- Use pcall to catch possible parse errors so that we can print out the name of the file that we failed to parse
	if pcall(function() json_data = json.decode(j) end) then
		return json_data
	else
		return nil
	end
end

local function validate(pokemon)
	if pokemon and type(pokemon) == "table" and pokemon.species and pokemon.species.current and
	pokemon.hp and pokemon.hp.current then
		return true
	end
	return nil
end

function M.import()
	local pokemon = load_json(clipboard.paste())
	if pokemon then
		if not validate(pokemon) then
			notify.notify("Pokemon data is incomplete")
			notify.notify(clipboard.paste())
			return 
		end
		storage.add(pokemon)
		dex.set(pokemon.species.current, dex.states.CAUGHT)
		if url.PARTY then
			msg.post(url.PARTY, "refresh")
		elseif url.STORAGE then
			msg.post(url.STORAGE, "inventory_updated")
			msg.post(url.STORAGE, "storage_updated")
		end
		notify.notify("Welcome " .. (pokemon.nickname or pokemon.species.current) .. "!")
		gameanalytics.addDesignEvent {
			eventId = "Share:Import",
			value = pokedex.get_index_number(pokemon.species.current)
		}
	else
		notify.notify("Could not parse pokemon data")
		notify.notify(clipboard.paste())
	end
end
local function encode_status(pokemon)
	local new = {}
	for s, _ in pairs(pokemon.statuses or {}) do
		new[statuses.string_to_state[s]] = true
	end
	pokemon.statuses = new
end

function M.get_clipboard()
	local pokemon = load_json(clipboard.paste())
	if pokemon then
		if not validate(pokemon) then
			return 
		end
		encode_status(pokemon)
		return pokemon
	end
	return
end

function M.load_qr()
	if camera.start_capture(camera.CAMERA_TYPE_BACK, camera.CAPTURE_QUALITY_HIGH) then
--[[
		-- start loop

		-- camera buffer should be:
		local info = camera.get_info()
		-- info has width, height

		-- has stream named rgb, type buffer,VALUE_TYPE_UINT8, value count 1
		local buffer = camera.get_frame()

		-- (Could theoretically display this if needed?)

		-- I'm not clear on whether the buffer is in the right format for qrcode, qrcore says it needs "An image buffer where the first stream must be of format UINT8 * 3, and have the dimensions width*height"
		-- but, assuming it does,
		local qrstring = qrcode.scan(buffer, info.width, info.height, 0) -- 0 is flip_x

		if qrstring ~= nil then
			-- qr code found, can exit loop and check if it's a pokemon string
			camera.stop_capture()
		else
			-- no qr code found
		end

		-- end loop

		--]]
	end
end

local function decode_status(pokemon)
	local new = {}
	for i, _ in pairs(pokemon.statuses or {}) do
		new[statuses.status_names[i]] = true
	end
	pokemon.statuses = new
end

function M.generate_qr(id)
	local pokemon = storage.get_copy(id)
	decode_status(pokemon)
	local p_json = ljson.encode(pokemon)
	return qrcode.generate(p_json)
end

function M.export(id)
	clipboard.copy(p_json)
	notify.notify((pokemon.nickname or pokemon.species.current) .. " copied to clipboard!")
	gameanalytics.addDesignEvent {
		eventId = "Share:Export",
		value = pokedex.get_index_number(pokemon.species.current)
	}
end

return M