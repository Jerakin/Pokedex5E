local button = require "utils.button"
local monarch = require "monarch.monarch"
local gooey = require "gooey.gooey"
local natures = require "pokedex.natures"
local _pokemon = require "pokedex.pokemon"
local pokedex = require "pokedex.pokedex"
local storage = require "pokedex.storage"
local gui_colors = require "utils.gui_colors"
local type_data = require "utils.type_data"
local url = require "utils.url"
local utils = require "utils.utils"
local movedex = require "pokedex.moves"
local selected_item
local flow = require "utils.flow"
local gooey_buttons = require "utils.gooey_buttons"


local STATS = {"STR", "DEX", "CON", "INT", "WIS", "CHA"}

local M = {}

local active_buttons = {}

local function pokemon_image(species)
	local pokemon_sprite, texture = pokedex.get_sprite(species)
	gui.set_texture(gui.get_node("change_pokemon/pokemon_sprite"), "sprite0")
	gui.play_flipbook(gui.get_node("change_pokemon/pokemon_sprite"), pokemon_sprite)
	gui.set_scale(gui.get_node("change_pokemon/pokemon_sprite"), vmath.vector3(3))
end

local function redraw(self)
	if not self.pokemon or self.pokemon.species.current == "" then
		return
	end
	local species_node = gui.get_node("change_pokemon/species")
	gui.set_text(species_node, self.pokemon.species.current)
	gui.set_text(gui.get_node("change_pokemon/txt_level"), "Lv. " .. self.level)

	gui.set_text(gui.get_node("change_pokemon/nature"), self.pokemon.nature or "No Nature")
	
	for i=1, 4 do 
		local move_node = gui.get_node("change_pokemon/move_" .. i)
		gui.set_text(move_node, "Move")
		gui.set_color(move_node, gui_colors.HERO_TEXT_FADED)
	end
	
	-- Moves
	for move, data in pairs(self.pokemon.moves) do
		local index = data.index
		local move_node = gui.get_node("change_pokemon/move_" .. index)
		gui.set_text(move_node, move:upper())
		gui.set_color(move_node, movedex.get_move_color(move))
	end

	-- Natures and attributes
	if not self.pokemon.nature or self.pokemon.nature == "" then
		return
	end
	
	local attributes = _pokemon.get_attributes(self.pokemon)
	for _, stat in pairs(STATS) do
		local n = gui.get_node("change_pokemon/asi/" .. stat .. "_MOD")
		
		gui.set_text(gui.get_node("change_pokemon/asi/" .. stat), attributes[stat])
		local mod = ""
		if self.increased_attributes[stat] >= 0 then
			mod = "+"
		end
		if self.increased_attributes[stat] >= 1 then
			gui.set_color(n, gui_colors.GREEN)
		else
			gui.set_color(n, gui_colors.TEXT)
		end
		gui.set_text(n, mod .. self.increased_attributes[stat])
	end

	-- ASI
	local max_improve_node = gui.get_node("change_pokemon/asi/asi_points")
	local available_at_level = pokedex.level_data(self.level).ASI
	local available_at_current_level = pokedex.level_data(_pokemon.get_current_level(self.pokemon)).ASI
	local available = (available_at_level - available_at_current_level)  * 2
	local current = available - self.ability_score_improvment
	gui.set_text(max_improve_node, current)
	if current == 0 then
		gui.set_color(max_improve_node, gui_colors.TEXT)
	elseif current >= 1 then
		gui.set_color(max_improve_node, gui_colors.GREEN)
	else
		gui.set_color(max_improve_node, gui_colors.RED)
	end
	
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
	monarch.show("moves_scrollist", {}, {species=self.pokemon.species.current, level=self.level, current_moves=self.pokemon.moves, message_id="move", sender=msg.url()})
end


function M.register_buttons_after_species(self)
	button.register("change_pokemon/btn_move_1", function()
		self.move_button_index = 1
		pick_move(self)
	end)

	button.register("change_pokemon/btn_move_2", function()
		self.move_button_index = 2
		pick_move(self)
	end)

	button.register("change_pokemon/btn_move_3", function()
		self.move_button_index = 3
		pick_move(self)
	end)

	button.register("change_pokemon/btn_move_4", function()
		self.move_button_index = 4
		pick_move(self)
	end)

	button.register("change_pokemon/nature", function()
		monarch.show("scrollist", {}, {items=natures.list, message_id="nature", sender=msg.url()})
	end)

	for _, s in pairs({"str", "dex", "con", "int", "wis", "cha"}) do
		local plus = {node="change_pokemon/asi/".. s .. "/btn_minus", func=function() decrease(self, s:upper()) end, refresh=gooey_buttons.minus_button}
		local minus = {node="change_pokemon/asi/".. s .. "/btn_plus", func=function() increase(self, s:upper()) end, refresh=gooey_buttons.plus_button}
		table.insert(active_buttons, plus)
		table.insert(active_buttons, minus)
	end

	local b = {node="change_pokemon/level/btn_plus", func=function()
		if self.level < 20 then
			self.level = self.level + 1
			redraw(self)
		end 
	end, refresh=gooey_buttons.plus_button}

	local a = {node="change_pokemon/level/btn_minus", func=function()
		if self.level > 1 and self.level > pokedex.get_minimum_wild_level(self.pokemon.species.current) then
			self.level = self.level - 1
			redraw(self)
		end
	end, refresh=gooey_buttons.minus_button}

	table.insert(active_buttons, a)
	table.insert(active_buttons, b)
end

function M.init(self, pokemon)
	msg.post(url.MENU, "hide")
	if pokemon then
		self.pokemon = utils.deep_copy(pokemon)
	end
	self.increased_attributes = {STR= 0,DEX= 0,CON= 0,INT= 0,WIS= 0,CHA= 0}
	self.level = 1
	self.ability_score_improvment = 0
	self.list_items = {}
	self.move_button_index = 0
	self.root = gui.get_node("root")

end

function M.final(self)
	msg.post(url.MENU, "show")
	active_buttons = {}
	button.unregister()
end

function M.on_message(self, message_id, message, sender)
	if message.item then
		if message_id == hash("nature") then
			self.pokemon.nature = message.item
			self.pokemon.attributes.nature = natures.get_nature_attributes(message.item)
			gui.set_color(gui.get_node("change_pokemon/nature"), gui_colors.HERO_TEXT)
		elseif message_id == hash("species") then
			self.pokemon = _pokemon.new({species=message.item})
			self.level = self.pokemon.level.current
			self.pokemon.nature = "No Nature"
			local starting_moves = pokedex.get_starting_moves(message.item)
			local moves = {}
			for i=1, 4 do
				if starting_moves[i] then
					local pp = movedex.get_move_pp(starting_moves[i])
					moves[starting_moves[i]] = {pp=pp, index=i}
				else
					local n = gui.get_node("change_pokemon/move_" .. i)
					gui.set_text(n, "Move")
					gui.set_color(n, gui_colors.HERO_TEXT_FADED)
				end
			end
			self.pokemon.moves = moves
			pokemon_image(message.item)
			gui.set_color(gui.get_node("change_pokemon/species"), gui_colors.TEXT)
			gui.set_font(gui.get_node("change_pokemon/species"), "title")
			gui.set_scale(gui.get_node("change_pokemon/species"), vmath.vector3(0.8))
			M.register_buttons_after_species(self)
			if self.register_buttons_after_species then self.register_buttons_after_species(self) end
		elseif message_id == hash("evolve") then
			flow.start(function()
				flow.until_true(function() return not monarch.is_busy() end)
				monarch.show("are_you_sure", nil, {title="Evolve at level ".. self.level .. "?", sender=msg.url(), data=message.item})
			end)
		else
			if message.item ~= "" then
				local n = gui.get_node("change_pokemon/move_" .. self.move_button_index)
				_pokemon.set_move(self.pokemon, message.item, self.move_button_index)
				
				gui.set_text(n, message.item)
				gui.set_color(n, movedex.get_move_color(message.item))
			end
		end
		redraw(self)
	end
	gui.set_enabled(self.root, true)
end

function M.on_input(action_id, action)
	button.on_input(action_id, action)
	gooey.button("change_pokemon/btn_close", action_id, action, function() monarch.back() end, gooey_buttons.close_button)
	for _, button in pairs(active_buttons) do
		gooey.button(button.node, action_id, action, button.func, button.refresh)
	end
end

return M