local share = require "pokedex.share"
local net_members = require "pokedex.network.net_members"
local net_member_name = require "pokedex.network.net_member_name"
local notify = require "utils.notify"

local KEY = "SEND_POKEMON"

local M = {}

M.SEND_TYPE_CATCH = "Catch"
M.SEND_TYPE_GIFT = "Gift"

local function on_pokemon_received(from_member_id, message)
	local pokemon = message.pokemon
	local send_type = message.send_type
	local from_name = net_member_name.get_name(from_member_id)
	
	if send_type and pokemon and share.validate(pokemon) then
		share.add_new_pokemon(pokemon)

		local notify_msg
		local pkmn_name = (pokemon.nickname or pokemon.species.current)
		if send_type == M.SEND_TYPE_CATCH then
			notify_msg = "YOU CAUGHT " .. pkmn_name .."!"
		elseif send_type == M.SEND_TYPE_GIFT then
			notify_msg = from_name .. " SENT YOU " .. pkmn_name .."!"
		else
			notify_msg = "WELCOME, " .. pkmn_name .. "!"
		end
		notify.notify(notify_msg)
	end	
end

function M.init()
	net_members.register_member_message_callback(KEY, on_pokemon_received)
end

function M.send_pokemon(member_id, pokemon_id, send_type)
	local pokemon = share.get_sendable_pokemon_copy(pokemon_id)

	local message = 
	{
		pokemon=pokemon,
		send_type=send_type,
	}

	net_members.send_message_to_member(KEY, message, member_id)
end

return M