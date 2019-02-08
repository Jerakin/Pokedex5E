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
	if not self.pokemon or self.pokemon.species.current == "" then
		return
	end
	local species_node = gui.get_node("spicies")
	gui.set_text(species_node, self.pokemon.species.current)
	gui.set_text(gui.get_node("txt_level"), "Lv. " .. self.level)
	
	-- Moves
	local index = 0
	for move, _ in pairs(self.pokemon.moves) do
		index = index + 1
		local move_node = gui.get_node("moves/move_" .. index)
		gui.set_text(move_node, move)
	end
	for i=index+1, 4 do
		local move_node = gui.get_node("moves/move_" .. i)
		gui.set_text(move_node, "")
	end

	-- Natures and attributes
	if not self.pokemon.nature or self.pokemon.nature == "" then
		return
	end
	
	local attributes = _pokemon.get_attributes(self.pokemon)
	for _, stat in pairs(STATS) do
		local n = gui.get_node("asi/" .. stat)
		gui.set_text(n, stat .. " " .. attributes[stat] .. "(" .. self.increased_attributes[stat] .. ")")
	end

	-- ASI
	local max_improve_node = gui.get_node("asi/title")
	local available_at_current_level = pokedex.level_data(self.level).ASI
	local available_at_caught_level = pokedex.level_data(self.pokemon.level.caught).ASI
	local available = (available_at_current_level - available_at_caught_level)  * 2
	gui.set_text(max_improve_node, "Available Points: " .. available - self.ability_score_improvment)

	if self.redraw then self.redraw(self) end
end

function M.redraw(self)
	redraw(self)
end

local function increase(self, stat)
	local max = _pokemon.get_max_attributes(self.pokemon)
	local attributes = _pokemon.get_attributes(self.pokemon)
	local m = attributes[stat] + self.increased_attributes[stat]
	if  m < max[stat] then
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
	if pokedex.is_pokemon(self.pokemon.species.current) then
		--gui.set_enabled(self.root, false)
		local available_moves = pokedex.get_pokemons_moves(self.pokemon.species.current, self.level)
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
	if pokemon then
		self.pokemon = utils.deep_copy(pokemon)
	end
	self.increased_attributes = {STR= 0,DEX= 0,CON= 0,INT= 0,WIS= 0,CHA= 0}
	self.level = 1
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
		if self.level < 20 then
			self.level = self.level + 1
			redraw(self)
		end
	end)
	button.register("btn_lvl_decrease/btn", function()
		if self.level > 1 and self.level > pokedex.get_minimum_wild_level(self.pokemon.species.current) then
			self.level = self.level - 1
			redraw(self)
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
			self.pokemon = _pokemon.new({species=message.item})
			self.level = self.pokemon.level.caught
			local starting_moves = pokedex.get_starting_moves(message.item)
			local moves = {}
			for i=1, 4 do
				if starting_moves[i] then
					local pp = pokedex.get_move_pp(starting_moves[i])
					moves[starting_moves[i]] = pp
				end
			end 
			pprint(starting_moves)
			self.pokemon.moves = moves
		else
			local n = gui.get_node("moves/move_" .. self.move_button_index)
			self.pokemon.moves[self.move_button_index] = message.item
			gui.set_text(n, message.item)
		end
		gui.set_enabled(self.root, true)
		redraw(self)
	end
end

function M.on_input(self, action_id, action)
	button.on_input(action_id, action)
end

return M