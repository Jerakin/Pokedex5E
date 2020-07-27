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

function M.add_new_pokemon(pokemon)
	storage.add(pokemon)
	dex.set(pokemon.species.current, dex.states.CAUGHT)
	if url.PARTY then
		msg.post(url.PARTY, "refresh")
	elseif url.STORAGE then
		msg.post(url.STORAGE, "inventory_updated")
		msg.post(url.STORAGE, "storage_updated")
	end
end

function M.import()
	local pokemon = load_json(clipboard.paste())
	if pokemon then
		if not M.validate(pokemon) then
			notify.notify("Pokemon data is incomplete")
			notify.notify(clipboard.paste())
			return 
		end
		M.add_new_pokemon(pokemon)
		notify.notify("Welcome " .. (pokemon.nickname or pokemon.species.current) .. "!")
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
		if not M.validate(pokemon) then
			return 
		end
		encode_status(pokemon)
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

function M.validate(pokemon)
	if pokemon and type(pokemon) == "table" and pokemon.species and pokemon.species.current and
	pokemon.hp and pokemon.hp.current then
		return true
	end
	return nil
end

function M.get_sendable_pokemon_copy(id)
	local pokemon = storage.get_copy(id)
	decode_status(pokemon)
	return pokemon
end

function M.export(id)
	local pokemon = M.get_sendable_pokemon_copy(id)
	
	local p_json = ljson.encode(pokemon)
	clipboard.copy(p_json)
	notify.notify((pokemon.nickname or pokemon.species.current) .. " copied to clipboard!")
end

return M