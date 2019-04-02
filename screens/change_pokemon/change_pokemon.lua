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


local config = {
	order={[1]=hash("change_pokemon/extra"), [2]=hash("change_pokemon/asi/root"), [3]=hash("change_pokemon/moves"), [4]=hash("change_pokemon/abilities")},
	start = vmath.vector3(0, 376, 0),
	[hash("change_pokemon/asi/root")] = {open=vmath.vector3(720, 420, 0), closed=vmath.vector3(720, 85, 0), active=true},
	[hash("change_pokemon/abilities")] = {open=vmath.vector3(720, 200, 0), closed=vmath.vector3(720, 50, 0), active=false},
	[hash("change_pokemon/moves")] = {open=vmath.vector3(720, 190, 0), closed=vmath.vector3(720, 50, 0), active=false},
	[hash("change_pokemon/extra")] = {open=vmath.vector3(720, 150, 0), closed=vmath.vector3(720, 0, 0), active=false},
	[hash("change_pokemon/nature")] = {open=vmath.vector3(720, 70, 0), closed=vmath.vector3(720, 0, 0), active=false}
}


local function update_sections(instant)
	local position = vmath.vector3(config.start)
	for _, node in ipairs(config.order) do 
		local size
		if config[node].active then
			size = config[node].open
		else
			size = config[node].closed
		end
		if instant then
			gui.set_size(gui.get_node(node), size)
			gui.set_position(gui.get_node(node), position)
		else
			gui.animate(gui.get_node(node), "position", position, gui.EASING_INSINE, 0.3)
			gui.animate(gui.get_node(node), "size", size, gui.EASING_INSINE, 0.3)
		end
		position.y = position.y - size.y
	end
end

local function pokemon_image(species)
	local pokemon_sprite, texture = pokedex.get_sprite(species)
	gui.set_texture(gui.get_node("change_pokemon/pokemon_sprite"), "sprite0")
	gui.play_flipbook(gui.get_node("change_pokemon/pokemon_sprite"), pokemon_sprite)
	gui.set_scale(gui.get_node("change_pokemon/pokemon_sprite"), vmath.vector3(3))
end

local function ability_checkbox_refresh(checkbox, node)
	if checkbox.released_now then
		if checkbox.checked then
			gui.set_enabled(node, true)
			gui.play_flipbook(node, hash("check_mark"))
		else
			gui.set_enabled(node, false)
		end
	end
end

local function ability_checkbox_toggle(self, checkbox, ability)
	self.ability_data[ability].add = checkbox.checked
end

local function redraw(self)
	if not self.pokemon or self.pokemon.species.current == "" then
		return
	end
	local species_node = gui.get_node("change_pokemon/species")
	gui.set_text(gui.get_node("change_pokemon/txt_level"), self.level)

	gui.set_text(gui.get_node("change_pokemon/nature"), self.pokemon.nature:upper() or "No Nature")
	
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
		local stat_num = gui.get_node("change_pokemon/asi/" .. stat)
		gui.set_text(stat_num, attributes[stat] + self.increased_attributes[stat])
		local mod = ""
		if self.increased_attributes[stat] >= 0 then
			mod = "+"
		end
		if self.increased_attributes[stat] >= 1 then
			gui.set_color(n, gui_colors.GREEN)
			gui.set_color(stat_num, gui_colors.GREEN)
		elseif self.increased_attributes[stat] <= -1 then
			gui.set_color(n, gui_colors.RED)
			gui.set_color(stat_num, gui_colors.RED)
		else
			gui.set_color(n, gui_colors.TEXT)
			gui.set_color(stat_num, gui_colors.TEXT)
		end
		gui.set_text(n, "(" .. mod .. self.increased_attributes[stat]..")")
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

	-- Abilities
	for name, entry in pairs(self.ability_data) do
		if entry.position ~= 1 then
			gui.delete_node(entry.node)
		end
	end
	self.ability_data = {}
	local ability_position
	local amount = 1
	local text_node
	local root_node
	local root_id
	for i, ability in pairs(self.abilities) do
		if i == 1 then
			text_node = gui.get_node("change_pokemon/ability/ability")
			root_node = gui.get_node("change_pokemon/ability/bg_ability")
			checkbox_node = gui.get_node("change_pokemon/ability/checkmark")
			root_id = "change_pokemon/ability/bg_ability"
			ability_position = gui.get_position(root_node)
		else
			local ability_nodes = gui.clone_tree(gui.get_node("change_pokemon/ability/bg_ability"))
			root_node = ability_nodes["change_pokemon/ability/bg_ability"]
			text_node = ability_nodes["change_pokemon/ability/ability"]
			checkbox_node = ability_nodes["change_pokemon/ability/checkmark"]
			root_id = "ability_root_" .. amount
			gui.set_id(root_node, root_id)
		end

		self.ability_data[ability] = {node=root_node, root_id=root_id, text=text_node, position=i, active=true, checkbox=checkbox_node, add=true}
		gui.set_text(text_node, ability:upper())
		gui.set_position(root_node, ability_position)
		ability_position.x = math.mod(i, 2) * 340
		ability_position.y = math.ceil((i-1)/2) * -40
		gooey.checkbox(root_id).set_checked(true)
		amount = amount + 1
	end

	if next(self.abilities) == nil then
		text_node = gui.get_node("change_pokemon/ability/ability")
		root_node = gui.get_node("change_pokemon/ability/bg_ability")
		checkbox_node = gui.get_node("change_pokemon/ability/checkmark")
		root_id = "change_pokemon/ability/bg_ability"
		ability_position = gui.get_position(root_node)
	else
		local ability_nodes = gui.clone_tree(gui.get_node("change_pokemon/ability/bg_ability"))
		root_node = ability_nodes["change_pokemon/ability/bg_ability"]
		text_node = ability_nodes["change_pokemon/ability/ability"]
		checkbox_node = ability_nodes["change_pokemon/ability/checkmark"]
		root_id = "ability_root_" .. amount
		gui.set_id(root_node, root_id)
	end

	if #self.abilities < 6 then  -- No more than 6 abilites for now!
		gui.set_text(text_node, "Add Other")
		gui.set_position(root_node, ability_position)
		self.ability_data["Add Other"] = {node=root_node, root_id=root_id, text=text_node, position=amount, active=true}
	else
		gui.set_enabled(root_node, false)
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
	local attributes = _pokemon.get_attributes(self.pokemon)
	local m = attributes[stat] + self.increased_attributes[stat]
	if m > 0 then
		self.increased_attributes[stat] = self.increased_attributes[stat] - 1
		self.ability_score_improvment = self.ability_score_improvment - 1
		redraw(self)
	end
end

local function pick_move(self)
	monarch.show("moves_scrollist", {}, {species=self.pokemon.species.current, level=self.level, current_moves=self.pokemon.moves, message_id="move", sender=msg.url()})
end


function M.register_buttons_after_species(self)

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
	if self.pokemon then
		self.abilities = _pokemon.get_abilities(self.pokemon)
	else
		self.abilities = {}
	end	
	self.ability_data = {}
	update_sections(true)
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
			gui.set_text(gui.get_node("change_pokemon/nature"), message.item)
			gui.set_color(gui.get_node("change_pokemon/nature"), gui_colors.HERO_TEXT)
		elseif message_id == hash("species") then
			if message.item == "" then
				return
			end
			self.pokemon = _pokemon.new({species=message.item})
			self.abilities = pokedex.get_pokemon_abilities(message.item)
			self.level = self.pokemon.level.current
			self.pokemon.nature = "No Nature"
			local starting_moves = pokedex.get_starting_moves(message.item)
			if #starting_moves > 4 then
				starting_moves = utils.shuffle2(starting_moves)
			end
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
			gui.set_color(gui.get_node("change_pokemon/pokemon_sprite"), vmath.vector4(1))
			gui.set_color(gui.get_node("change_pokemon/species"), gui_colors.TEXT)
			gui.set_text(gui.get_node("change_pokemon/species"), self.pokemon.species.current:upper())
			gui.set_scale(gui.get_node("change_pokemon/species"), vmath.vector3(0.8))
			M.register_buttons_after_species(self)
			if self.register_buttons_after_species then self.register_buttons_after_species(self) end
		elseif message_id == hash("evolve") then
			flow.start(function()
				flow.until_true(function() return not monarch.is_busy() end)
				monarch.show("are_you_sure", nil, {title="Evolve at level ".. self.level .. "?", sender=msg.url(), data=message.item})
			end)
		elseif message_id == hash("abilities") then
			for _, ability in pairs(self.abilities) do 
				if ability == message.item then
					return
				end
			end
			table.insert(self.abilities, message.item)
			redraw(self)
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

local function add_ability(self)
	local a = utils.deep_copy(pokedex.ability_list())
	local filtered = {}
	local add
	for _, new_ability in pairs(a) do 
		add = true
		for _, ability in pairs(self.abilities) do
			if new_ability == ability then
				add = false
			end
		end
		if add then
			table.insert(filtered, new_ability)
		end
		
	end
	monarch.show("scrollist", {}, {items=filtered, message_id="abilities", sender=msg.url(), title="Pick Ability"})
end

local function ability_buttons(self, action_id, action)
	gooey.button("change_pokemon/btn_reset_abilities", action_id, action, function()
		self.abilities = pokedex.get_pokemon_abilities(_pokemon.get_current_species(self.pokemon))
		redraw(self)
	end)
	for ability, data in pairs(self.ability_data) do
		if ability == "Add Other" then
			gooey.button(data.root_id, action_id, action, function() add_ability(self) end)
		else
			gooey.checkbox(data.root_id, action_id, action, function(c) ability_checkbox_toggle(self, c, ability) end, function(c) ability_checkbox_refresh(c, data.checkbox) end)
		end
	end
end

local function extra_buttons(self, action_id, action)
	gooey.button("change_pokemon/level/btn_plus", action_id, action, function()
		if self.level < 20 then
			self.level = self.level + 1
			redraw(self)
		end 
	end, gooey_buttons.plus_button)

	gooey.button("change_pokemon/level/btn_minus", action_id, action, function()
		if self.level > 1 and self.level > pokedex.get_minimum_wild_level(self.pokemon.species.current) then
			self.level = self.level - 1
			redraw(self)
		end
	end, gooey_buttons.minus_button)
end

local function move_buttons(self, action_id, action)
	gooey.button("change_pokemon/btn_move_1", action_id, action, function()
		self.move_button_index = 1
		pick_move(self)
	end)

	gooey.button("change_pokemon/btn_move_2", action_id, action, function()
		self.move_button_index = 2
		pick_move(self)
	end)

	gooey.button("change_pokemon/btn_move_3", action_id, action, function()
		self.move_button_index = 3
		pick_move(self)
	end)

	gooey.button("change_pokemon/btn_move_4", action_id, action, function()
		self.move_button_index = 4
		pick_move(self)
	end)
end

local function attribute_buttons(self, action_id, action)
	gooey.button("change_pokemon/asi/str/btn_minus", action_id, action, function() decrease(self, "STR") end,gooey_buttons.minus_button)
	gooey.button("change_pokemon/asi/str/btn_plus", action_id, action, function() increase(self, "STR") end, gooey_buttons.plus_button)
	
	gooey.button("change_pokemon/asi/con/btn_minus", action_id, action, function() decrease(self, "CON") end,gooey_buttons.minus_button)
	gooey.button("change_pokemon/asi/con/btn_plus", action_id, action, function() increase(self, "CON") end, gooey_buttons.plus_button)
	
	gooey.button("change_pokemon/asi/dex/btn_minus", action_id, action, function() decrease(self, "DEX") end,gooey_buttons.minus_button)
	gooey.button("change_pokemon/asi/dex/btn_plus", action_id, action, function() increase(self, "DEX") end, gooey_buttons.plus_button)
	
	gooey.button("change_pokemon/asi/int/btn_minus", action_id, action, function() decrease(self, "INT") end,gooey_buttons.minus_button)
	gooey.button("change_pokemon/asi/int/btn_plus", action_id, action, function() increase(self, "INT") end, gooey_buttons.plus_button)
	
	gooey.button("change_pokemon/asi/wis/btn_minus", action_id, action, function() decrease(self, "WIS") end, gooey_buttons.minus_button)
	gooey.button("change_pokemon/asi/wis/btn_plus", action_id, action, function() increase(self, "WIS") end, gooey_buttons.plus_button)
	
	gooey.button("change_pokemon/asi/cha/btn_minus", action_id, action, function() decrease(self, "CHA") end, gooey_buttons.minus_button)
	gooey.button("change_pokemon/asi/cha/btn_plus", action_id, action, function() increase(self, "CHA") end, gooey_buttons.plus_button)
end

function M.on_input(self, action_id, action)
	button.on_input(action_id, action)
	gooey.button("change_pokemon/btn_close", action_id, action, function() monarch.back() end, gooey_buttons.close_button)
	
	for _, button in pairs(active_buttons) do
		gooey.button(button.node, action_id, action, button.func, button.refresh)
	end

	gooey.button("change_pokemon/asi/btn_collapse", action_id, action, function()
		config[hash("change_pokemon/asi/root")].active = not config[hash("change_pokemon/asi/root")].active
		if config[hash("change_pokemon/asi/root")].active then
			config[hash("change_pokemon/moves")].active = false
			config[hash("change_pokemon/abilities")].active = false
		end
		update_sections()
	end)

	gooey.button("change_pokemon/btn_collapse_moves", action_id, action, function()
		config[hash("change_pokemon/moves")].active = not config[hash("change_pokemon/moves")].active
		if config[hash("change_pokemon/moves")].active then
			config[hash("change_pokemon/abilities")].active = false
			config[hash("change_pokemon/asi/root")].active = false
		end
		update_sections()
	end)

	gooey.button("change_pokemon/btn_collapse_abilities", action_id, action, function()
		config[hash("change_pokemon/abilities")].active = not config[hash("change_pokemon/abilities")].active
		if config[hash("change_pokemon/abilities")].active then
			config[hash("change_pokemon/asi/root")].active = false
			config[hash("change_pokemon/moves")].active = false
		end
		update_sections()
	end)
	
	if config[hash("change_pokemon/abilities")].active then
		ability_buttons(self, action_id, action)
	end
	if config[hash("change_pokemon/asi/root")].active then
		attribute_buttons(self, action_id, action)
	end
	if config[hash("change_pokemon/moves")].active then
		move_buttons(self, action_id, action)
	end
	if config[hash("change_pokemon/extra")].active then
		extra_buttons(self, action_id, action)
	end
	if config[hash("change_pokemon/nature")].active then
		gooey.button("change_pokemon/nature", action_id, action, function()
			monarch.show("scrollist", {}, {items=natures.list, message_id="nature", sender=msg.url(), title="Pick Nature"})
		end)
	end
	
end

return M