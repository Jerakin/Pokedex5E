local ljson = require "defsave.json"
local storage = require "pokedex.storage"
local url = require "utils.url"
local notify = require "utils.notify"
local monarch = require "monarch.monarch"
local dex = require "pokedex.dex"
local pokedex = require "pokedex.pokedex"
local statuses = require "pokedex.statuses"
local _file = require "utils.file"
local platform = require "utils.platform"

local M = {}

-- For checking if sharing is enabled
M.ENABLED = {
	CLIPBOARD = clipboard ~= nil,
	QRCODE_GENERATE = true,
	QRCODE_READ = platform.PHONE or platform.MACOS,
}
M.ENABLED.ANY = M.ENABLED.CLIPBOARD or M.ENABLED.QRCODE_READ


function M.validate(pokemon)
	if pokemon and type(pokemon) == "table" and pokemon.species and pokemon.species.current and
	pokemon.hp and pokemon.hp.current then
		return true
	end
	return nil
end

function M.import()
	local pokemon = _file.load_json(clipboard.paste())
	if pokemon then
		if not M.validate(pokemon) then
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
	else
		notify.notify("Could not parse pokemon data")
		notify.notify(clipboard.paste())
	end
end
function M.encode_status(pokemon)
	local new = {}
	for s, _ in pairs(pokemon.statuses or {}) do
		new[statuses.string_to_state[s]] = true
	end
	pokemon.statuses = new
end

function M.get_clipboard()
	local pokemon = _file.load_json(clipboard.paste())
	if pokemon then
		if not M.validate(pokemon) then
			return 
		end
		M.encode_status(pokemon)
		return pokemon
	end
	return
end

local function decode_status(pokemon)
	local new = {}
	for i, _ in pairs(pokemon.statuses or {}) do
		new[statuses.status_names[i]] = true
	end
	pokemon.statuses = new
end

local function serialize_pokemon(pokemon)
	decode_status(pokemon)
	return ljson.encode(pokemon)
end

function M.generate_qr(id)
	local pokemon = storage.get_copy(id)
	return qrcode.generate(serialize_pokemon(pokemon))
end

function M.export(id)
	local pokemon = storage.get_copy(id)
	clipboard.copy(serialize_pokemon(pokemon))
	notify.notify((pokemon.nickname or pokemon.species.current) .. " copied to clipboard!")
end

return M