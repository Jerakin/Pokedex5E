local ljson = require "defsave.json"
local storage = require "pokedex.storage"
local url = require "utils.url"
local notify = require "utils.notify"
local monarch = require "monarch.monarch"
local dex = require "pokedex.dex"
local pokedex = require "pokedex.pokedex"

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
	if pokemon and pokemon.species and pokemon.species.current and
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

function M.get_clipboard()
	local pokemon = load_json(clipboard.paste())
	if pokemon then
		if not validate(pokemon) then
			return 
		end
		return pokemon
	end
	return
end


function M.export(id)
	local pokemon = storage.get_copy(id)
	
	local p_json = ljson.encode(pokemon)
	clipboard.copy(p_json)
	notify.notify((pokemon.nickname or pokemon.species.current) .. " copied to clipboard!")
	gameanalytics.addDesignEvent {
		eventId = "Share:Export",
		value = pokemon.species.current
	}
end

return M