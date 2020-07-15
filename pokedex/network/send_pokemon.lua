local dex = require "pokedex.dex"
local netcore = require "pokedex.network.netcore"
local notify = require "utils.notify"
local storage = require "pokedex.storage"
local url = require "utils.url"


local KEY = "SEND_POKEMON"

-- TODO maybe make use of share.lua for all this
local function validate(pokemon)
	if pokemon and type(pokemon) == "table" and pokemon.species and pokemon.species.current and
	pokemon.hp and pokemon.hp.current then
		return true
	end
	return nil
end

local function on_pokemon_receieved(pokemon)
	if pokemon and validate(pokemon) then
		storage.add(pokemon)
		dex.set(pokemon.species.current, dex.states.CAUGHT)
		if url.PARTY then
			msg.post(url.PARTY, "refresh")
		elseif url.STORAGE then
			msg.post(url.STORAGE, "inventory_updated")
			msg.post(url.STORAGE, "storage_updated")
		end
		notify.notify("Welcome " .. (pokemon.nickname or pokemon.species.current) .. "!")
	end	
end

local M = {}

function M.init()
	netcore.register_client_callback(KEY, on_pokemon_receieved)
end

function M.send_pokemon(pokemon)
	netcore.send_to_client(KEY, pokemon)
end

return M