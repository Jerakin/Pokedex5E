local button = require "utils.button"
local monarch = require "monarch.monarch"
local gooey = require "gooey.gooey"
local natures = require "pokedex.natures"
local _pokemon = require "pokedex.pokemon"
local pokedex = require "pokedex.pokedex"
local storage = require "pokedex.storage"

local utils = require "utils.utils"

local selected_item
local STATS = {"STR", "DEX", "CON", "INT", "WIS", "CHA"}

local M = {}

local function redraw(self)
	for _, stat in pairs(STATS) do
		local n = gui.get_node("asi/" .. stat)
		local total = self.pokemon.attributes.base[stat] + self.pokemon.attributes.increased[stat] + self.pokemon.attributes.nature[stat]
		gui.set_text(n, stat .. " " .. total .. "(" .. self.increased_attributes[stat] .. ")")
	end

	local level_node = gui.get_node("txt_level")
	gui.set_text(level_node, "Lv. " .. self.pokemon.level)

	local species_node = gui.get_node("spicies")
	local max_improve_node = gui.get_node("asi/title")
	if self.pokemon.species == "" then
		gui.set_text(species_node, "Pokémon")
		gui.set_text(max_improve_node, "Available Points: 0")
	else
		local available_at_current_level = _pokemon.level_data(self.pokemon.min_level).ASI
		local available_at_new_level = _pokemon.level_data(self.pokemon.level).ASI
		local available = (available_at_new_level - available_at_current_level) * 2
		gui.set_text(max_improve_node, "Available Points: " .. available - self.ability_score_improvment)
		gui.set_text(species_node, self.pokemon.species)
	end

	local move_1_node = gui.get_node("moves/move_1")
	local move_2_node = gui.get_node("moves/move_2")
	local move_3_node = gui.get_node("moves/move_3")
	local move_4_node = gui.get_node("moves/move_4")

	gui.set_text(move_1_node, self.pokemon.moves[1] or "")
	gui.set_text(move_2_node, self.pokemon.moves[2] or "")
	gui.set_text(move_3_node, self.pokemon.moves[3] or "")
	gui.set_text(move_4_node, self.pokemon.moves[4] or "")
	if self.redraw then self.redraw(self) end
end

function M.redraw(self)
	redraw(self)
end

local function increase(self, stat)
	local total = self.pokemon.attributes.base[stat] + self.pokemon.attributes.increased[stat]
	if total + self.increased_attributes[stat] < self.pokemon.attributes.max[stat] then
		self.increased_attributes[stat] = self.increased_attributes[stat] + 1
		self.ability_score_improvment = self.ability_score_improvment + 1
		redraw(self)
	end
	
end

local function decrease(self, stat)
	if self.increased_attributes[stat] > 0 then
		self.increased_attributes[stat] = self.increased_attributes[stat] - 1
		self.ability_score_improvment = self.ability_score_improvment - 1
		redraw(self)
	end
end

local function pick_move(self)
	if pokedex.is_pokemon(self.pokemon.species) then
		gui.set_enabled(self.root, false)
		local available_moves = pokedex.get_pokemons_moves(self.pokemon.species, self.pokemon.level)
		for _, move in pairs(self.pokemon.moves) do
			for i, selected_move in pairs(available_moves) do
				if move == selected_move then
					table.remove(available_moves, i)
				end
			end
		end

		monarch.show("scrollist", {}, {items=available_moves, message_id="move", sender=msg.url()})
	end
end

function M.init(self, pokemon)
	self.old_species = pokemon.species
	self.increased_attributes = {STR=0, DEX=0, CON=0, INT=0, WIS=0, CHA=0}
	self.pokemon = {moves={}}
	self.pokemon.id = pokemon.id
	self.pokemon.species = pokemon.species
	self.pokemon.level = pokemon.level
	self.pokemon.min_level = pokemon.min_level or pokemon.level
	self.pokemon.attributes = pokemon.attributes
	self.pokemon.attributes.max = {}
	self.pokemon.nature = pokemon.nature
	
	for _, stat in pairs(STATS) do
		self.pokemon.attributes.max[stat] = 20
		if pokemon.attributes.nature[stat] > 0 then
			self.pokemon.attributes.max[stat] = self.pokemon.attributes.max[stat] + pokemon.attributes.nature[stat]
		end
	end
	
	
	self.ability_score_improvment = 0
	self.list_items = {}
	self.state = 0
	self.move_button_index = 0

	self.root = gui.get_node("root")

	button.register("asi/btn_str_decrease/btn", function()
		decrease(self, "STR")
	end)
	button.register("asi/btn_str_increase/btn", function()
		increase(self, "STR")
	end)
	button.register("asi/btn_dex_decrease/btn", function()
		decrease(self, "DEX")
	end)
	button.register("asi/btn_dex_increase/btn", function()
		increase(self, "DEX")
	end)
	button.register("asi/btn_con_decrease/btn", function()
		decrease(self, "CON")
	end)
	button.register("asi/btn_con_increase/btn", function()
		increase(self, "CON")
	end)
	button.register("asi/btn_int_decrease/btn", function()
		decrease(self, "INT")
	end)
	button.register("asi/btn_int_increase/btn", function()
		increase(self, "INT")
	end)
	button.register("asi/btn_wis_decrease/btn", function()
		decrease(self, "WIS")
	end)
	button.register("asi/btn_wis_increase/btn", function()
		increase(self, "WIS")
	end)
	button.register("asi/btn_cha_decrease/btn", function()
		decrease(self, "CHA")
	end)
	button.register("asi/btn_cha_increase/btn", function()
		increase(self, "CHA")
	end)

	button.register("btn_lvl_increase/btn", function()
		if pokedex.is_pokemon(self.pokemon.species) and self.pokemon.level < 20 then
			self.pokemon.level = self.pokemon.level + 1
			redraw(self)
		end
	end)
	button.register("btn_lvl_decrease/btn", function()
		if pokedex.is_pokemon(self.pokemon.species) then
			if self.pokemon.level > 1 and self.pokemon.level > pokedex.minumum_level(self.pokemon.species) then
				self.pokemon.level = self.pokemon.level - 1
				redraw(self)
			end
		end
	end)

	button.register("moves/btn_move_1", function()
		self.move_button_index = 1
		pick_move(self)
	end)

	button.register("moves/btn_move_2", function()
		self.move_button_index = 2
		pick_move(self)
	end)

	button.register("moves/btn_move_3", function()
		self.move_button_index = 3
		pick_move(self)
	end)

	button.register("moves/btn_move_4", function()
		self.move_button_index = 4
		pick_move(self)
	end)
end

function M.final(self)
	button.unregister()
end


function M.on_message(self, message_id, message, sender)
	if message.item then
		if message_id == hash("nature") then
			self.pokemon.nature = message.item
			self.pokemon.attributes.nature = natures.get_nature_attributes(message.item)
		elseif message_id == hash("species") then
			self.pokemon.species = message.item
			self.pokemon.moves = {}
			self.pokemon.min_level = pokedex.minumum_level(message.item)
			self.pokemon.attributes.base = pokedex.get_base_attributes(message.item)
			self.pokemon.level = self.pokemon.min_level
			local m = pokedex.get_starting_moves(message.item)
			for i=1, 4 do
				if m[i] then
					table.insert(self.pokemon.moves, m[i])
				else
					table.insert(self.pokemon.moves, "")
				end
			end 
		else
			local n = gui.get_node("moves/move_" .. self.move_button_index)
			self.pokemon.moves[self.move_button_index] = message.item
			gui.set_text(n, message.item)
		end
	end
	redraw(self)
	gui.set_enabled(self.root, true)
end

function M.on_input(self, action_id, action)
	button.on_input(action_id, action)
end

return M