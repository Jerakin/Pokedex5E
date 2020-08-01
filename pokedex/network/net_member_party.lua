local net_members = require "pokedex.network.net_members"
local pokemon = require "pokedex.pokemon"
local storage = require "pokedex.storage"

local NAME_KEY = "party"

local M = {}

local function party_changed()
	local new_party = {}
	for _,id in ipairs(storage.list_of_ids_in_inventory()) do
		local species = storage.get_pokemon_species(id)
		table.insert(new_party,
		{
			id=id,
			species=species,
		})
	end
	net_members.update_member_data(NAME_KEY, new_party)
end

function M.init()
	party_changed()
	storage.register_party_changed_cb(party_changed)
end

function M.get_party(member_id)
	return net_members.get_data_for_member(NAME_KEY, member_id) or {}
end

return M