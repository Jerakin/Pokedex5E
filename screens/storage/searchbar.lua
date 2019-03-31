local storage = require "pokedex.storage"
local _pokemon = require "pokedex.pokemon"
local gooey = require "gooey.gooey"
local gui_colors = require "utils.gui_colors"
local url = require "utils.url"

local M = {}

function M.filter_list(self, search_string)
	local function starts_with(str, start)
		return string.lower(str):sub(1, #start) == string.lower(start)
	end

	if #search_string > 0 then
		self.filtered_list = {}
		for i=#self.all_pokemons, 1, -1 do
			local p = storage.get_copy(self.all_pokemons[i])
			if starts_with(_pokemon.get_current_species(p), search_string) then
				table.insert(self.filtered_list, 1, self.all_pokemons[i])
			end
		end
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
		M.filter_list(self, input.text)
	else
		gui.set_enabled(cursor, false)
		gui.cancel_animation(cursor, gui.PROP_COLOR)
	end
end

function M.on_input(self, action_id, action)
	gooey.input("search_text", gui.KEYBOARD_TYPE_DEFAULT, action_id, action, nil, function(input)
		refresh_input(self, input, "search_text")
	end)
end

return M