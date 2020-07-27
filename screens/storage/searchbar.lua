local storage = require "pokedex.storage"
local _pokemon = require "pokedex.pokemon"
local gooey = require "gooey.gooey"
local gui_colors = require "utils.gui_colors"
local url = require "utils.url"
local dex = require "pokedex.dex"
local type_data = require "utils.type_data"
local platform = require "utils.platform"

local M = {}

local function starts_with(str, start)
	return string.lower(str):sub(1, #start) == string.lower(start)
end

local function filter_type(self, search_string)
	for i=#self.all_pokemons, 1, -1 do
		local p = storage.get_copy(self.all_pokemons[i])
		for _, type in pairs(_pokemon.get_type(p)) do
			if type:lower() == search_string:lower() then
				table.insert(self.filtered_list, 1, self.all_pokemons[i])
			end
		end
	end
end

local function filter_species(self, search_string)
	for i=#self.all_pokemons, 1, -1 do
		local p = storage.get_copy(self.all_pokemons[i])
		if starts_with(_pokemon.get_current_species(p), search_string) then
			table.insert(self.filtered_list, 1, self.all_pokemons[i])
		end
	end
end

local function filter_index(self, search_string)
	for i=#self.all_pokemons, 1, -1 do
		local p = storage.get_copy(self.all_pokemons[i])
		if starts_with(_pokemon.get_index_number(p), search_string) then
			table.insert(self.filtered_list, 1, self.all_pokemons[i])
		end
	end
end


function M.filter_list(self, search_string)
	if #search_string > 0 then
		local filter = filter_species
		if tonumber(search_string) ~= nil then
			filter = filter_index
		else
			for type, _ in pairs(type_data) do
				if type:lower() == search_string:lower() then
					filter = filter_type
					break
				end
			end
		end
		self.filtered_list = {}
		filter(self, search_string:lower())
	else
		self.filtered_list = self.all_pokemons
	end
	msg.post(url.STORAGE, "search")
end

local function refresh_input(self, input, node_id)
	if input.empty and not input.selected then
		gui.set_text(input.node, "search")
		gui.set_color(input.node, gui_colors.HERO_TEXT_FADED)
	end

	local cursor = gui.get_node("cursor")
	if input.selected then
		if input.empty then
			gui.set_text(self.text_node, "")
		end
		self.all_pokemons = storage.list_of_ids_in_storage()
		gui.set_enabled(cursor, true)
		gui.set_position(cursor, vmath.vector3(input.total_width, 0, 0))
		gui.cancel_animation(cursor, gui.PROP_COLOR)
		gui.set_color(input.node, gui_colors.HERO_TEXT)
		gui.animate(cursor, gui.PROP_COLOR, vmath.vector4(1,1,1,0), gui.EASING_INSINE, 0.8, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
		M.filter_list(self, input.text .. input.marked_text)
	else
		gui.set_enabled(cursor, false)
		gui.cancel_animation(cursor, gui.PROP_COLOR)
	end
end

local enabled = vmath.vector3(0)
local disabled = vmath.vector3(41, -517, 0)

local function keyboard_toggle(toggle)
	local pos = disabled
	if platform.MOBILE_PHONE then
		if toggle then
			pos = enabled
		end
		gui.set_position(gui.get_node("search"), pos)
	end
end

function M.on_input(self, action_id, action)
	local input = gooey.input("search_text", gui.KEYBOARD_TYPE_DEFAULT, action_id, action, {use_marked_text=false}, function(input)
		refresh_input(self, input, "search_text")
	end)
	if input.enabled then
		if input.selected then
			keyboard_toggle(true)
		else
			keyboard_toggle(false)
		end
	end
end

return M