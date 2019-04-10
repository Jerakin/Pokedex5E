local button = require "utils.button"
local monarch = require "monarch.monarch"
local gooey = require "gooey.gooey"
local natures = require "pokedex.natures"
local _pokemon = require "pokedex.pokemon"
local _feats = require "pokedex.feats"
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
local move_buttons_list = {}

local button_state = {[true]="minus", [false]="plus"}

M.config = {
	order={
		[1]=hash("change_pokemon/nature"), [2]=hash("change_pokemon/extra") ,
		[3]=hash("change_pokemon/asi/root"), [4]=hash("change_pokemon/moves"),
		[5]=hash("change_pokemon/abilities"), [6]=hash("change_pokemon/feats")
	},
	start = vmath.vector3(0, 452, 0),
	[hash("change_pokemon/asi/root")] = {open=vmath.vector3(720, 420, 0), closed=vmath.vector3(720, 85, 0), active=true},
	[hash("change_pokemon/abilities")] = {open=vmath.vector3(720, 200, 0), closed=vmath.vector3(720, 50, 0), active=false},
	[hash("change_pokemon/moves")] = {open=vmath.vector3(720, 190, 0), closed=vmath.vector3(720, 50, 0), active=false},
	[hash("change_pokemon/extra")] = {open=vmath.vector3(720, 150, 0), closed=vmath.vector3(720, 0, 0), active=true},
	[hash("change_pokemon/feats")] = {open=vmath.vector3(720, 200, 0), closed=vmath.vector3(720, 50, 0), active=false},
	[hash("change_pokemon/nature")] = {open=vmath.vector3(720, 70, 0), closed=vmath.vector3(720, 0, 0), active=true}
}
local node_index = 0
local function set_id(node)
	local id = "change_pokemon" .. node_index
	gui.set_id(node, id)
	node_index = node_index + 1
	return id
end

local function collapse_buttons()
	gui.play_flipbook(gui.get_node("change_pokemon/asi/btn_collapse"), button_state[M.config[hash("change_pokemon/asi/root")].active])
	gui.play_flipbook(gui.get_node("change_pokemon/btn_collapse_moves"), button_state[M.config[hash("change_pokemon/moves")].active])
	gui.play_flipbook(gui.get_node("change_pokemon/btn_collapse_abilities"), button_state[M.config[hash("change_pokemon/abilities")].active])
	gui.play_flipbook(gui.get_node("change_pokemon/btn_collapse_feats"), button_state[M.config[hash("change_pokemon/feats")].active])
	gui.set_enabled(gui.get_node("change_pokemon/btn_reset_abilities"), M.config[hash("change_pokemon/abilities")].active)
end

local function update_sections(instant)
	local position = vmath.vector3(M.config.start)
	for _, node in ipairs(M.config.order) do 
		local size
		if M.config[node].active then
			size = M.config[node].open
		else
			size = M.config[node].closed
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
	collapse_buttons()
end

local function pokemon_image(species)
	local pokemon_sprite, texture = pokedex.get_sprite(species)
	gui.set_texture(gui.get_node("change_pokemon/pokemon_sprite"), "sprite0")
	gui.play_flipbook(gui.get_node("change_pokemon/pokemon_sprite"), pokemon_sprite)
	gui.set_scale(gui.get_node("change_pokemon/pokemon_sprite"), vmath.vector3(3))
end

local function redraw_list(data_table, entry_table, text_hash, btn_hash, delete_hash, root_hash)
	update_sections()
	for _, entry in pairs(data_table) do
		gui.delete_node(entry.root)
		if entry.position ~= 1 then
			--gui.delete_node(entry.root)
		end
	end
	data_table = {}
	local ability_position = vmath.vector3()
	local amount = 1
	local text_node
	local button_node
	local delete_node
	local btn_id
	local delete_id
	for i, ability in pairs(entry_table) do
		local nodes = gui.clone_tree(gui.get_node(root_hash))
		gui.set_enabled(nodes[root_hash], true)
		button_node = nodes[btn_hash]
		text_node = nodes[text_hash]
		delete_node = nodes[delete_hash]
		btn_id = "root_" .. ability .. i
		delete_id = "delete_" .. ability .. i
		gui.set_id(button_node, btn_id)
		gui.set_id(delete_node, delete_id)

		gui.set_color(text_node, gui_colors.BLACK)
		gui.set_enabled(delete_node, true)
		table.insert(data_table, {name=ability, button=btn_id, root=nodes[root_hash], text=text_node, position=i, active=true, delete=delete_id, add=true})
		gui.set_text(text_node, ability:upper())
		gui.set_position(nodes[root_hash], ability_position)
		ability_position.x = math.mod(i, 2) * 340
		ability_position.y = math.ceil((i-1)/2) * -40
		amount = amount + 1
	end
	local nodes = gui.clone_tree(gui.get_node(root_hash))
	gui.set_enabled(nodes[root_hash], true)
	button_node = nodes[btn_hash]
	text_node = nodes[text_hash]
	btn_id = set_id(button_node)

	gui.set_text(text_node, "ADD NEW")
	gui.set_color(text_node, gui_colors.HERO_TEXT_FADED)
	gui.set_position(nodes[root_hash], ability_position)
	gui.set_enabled(nodes[delete_hash], false)
	table.insert(data_table, {name="Add Other", button=btn_id, root=nodes[root_hash], text=text_node, position=amount, active=true})

	return data_table, entry_table
end


local function redraw_moves(self)
	local position = vmath.vector3()
	M.config[hash("change_pokemon/moves")].open.y = M.config[hash("change_pokemon/moves")].closed.y + math.ceil(self.move_count / 2) * 60

	for _, b in pairs(move_buttons_list) do
		gui.delete_node(gui.get_node(b.node))
		gui.delete_node(b.text)
	end

	move_buttons_list = {}
	for i=1, self.move_count do
		local nodes = gui.clone_tree(self.move_node)
		local txt = nodes["change_pokemon/txt_move"]
		local btn = nodes["change_pokemon/btn_move"]
		gui.set_id(txt, "move_txt" .. i)
		gui.set_id(btn, "move_btn" .. i)
		gui.set_position(btn, position)
		gui.set_enabled(btn, true)
		gui.set_color(txt, gui_colors.HERO_TEXT_FADED)
		table.insert(move_buttons_list, {node="move_btn" .. i, text=txt})
		position.x = math.mod(i, 2) * 320
		position.y = math.ceil((i-1)/2) * -60
	end
	local index = 1
	for move, data in pairs(self.pokemon.moves) do
		if move_buttons_list[index] then
			local move_node = move_buttons_list[index].text
			gui.set_text(move_node, move:upper())
			gui.set_color(move_node, movedex.get_move_color(move))
			index = index + 1
		end
	end
end


local function redraw(self)
	if not self.pokemon or self.pokemon.species.current == "" then
		return
	end
	local species_node = gui.get_node("change_pokemon/species")
	gui.set_text(gui.get_node("change_pokemon/txt_level"), self.level)
	
	gui.set_text(gui.get_node("change_pokemon/nature"), self.pokemon.nature:upper() or "No Nature")

	-- Moves
	redraw_moves(self)

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
	local root_id = hash("change_pokemon/ability/root")
	local text_id = hash("change_pokemon/ability/txt")
	local btn_id = hash("change_pokemon/ability/btn_entry")
	local del_id = hash("change_pokemon/ability/btn_delete")
	local nodes = gui.clone_tree(gui.get_node(root_id))
	M.config[hash("change_pokemon/abilities")].open.y = M.config[hash("change_pokemon/abilities")].closed.y + (math.ceil(#self.abilities / 2) + 1) * 40
	self.ability_data, self.abilities = redraw_list(self.ability_data, self.abilities, text_id, btn_id, del_id, root_id)

	-- Feats
	local root_id = hash("change_pokemon/feat/root")
	local text_id = hash("change_pokemon/feat/txt")
	local btn_id = hash("change_pokemon/feat/btn_entry")
	local del_id = hash("change_pokemon/feat/btn_delete")
	M.config[hash("change_pokemon/feats")].open.y = M.config[hash("change_pokemon/feats")].closed.y + (math.ceil(#self.feats / 2) + 1) * 40
	self.feats_data, self.feats = redraw_list(self.feats_data, self.feats, text_id, btn_id, del_id, root_id)

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
	gui.set_enabled(gui.get_node("change_pokemon/feat/root"), false)
	gui.set_enabled(gui.get_node("change_pokemon/ability/root"), false)
	gui.set_enabled(gui.get_node("change_pokemon/btn_reset_abilities"), false)
	
	self.move_node = gui.get_node("change_pokemon/btn_move")
	gui.set_enabled(self.move_node, false)
	if self.pokemon then
		local _, count = _pokemon.have_feat(self.pokemon, "Extra Move")
		self.move_count = 4 + count
		self.abilities = _pokemon.get_abilities(self.pokemon, true)
		self.feats = _pokemon.get_feats(self.pokemon)
	else
		self.move_count = 4
		self.feats = {}
		self.abilities = {}
	end	
	self.ability_data = {}
	self.feats_data = {}
	
	update_sections(true)
end

function M.final(self)
	msg.post(url.MENU, "show")
	active_buttons = {}
	move_buttons_list = {}
	button.unregister()
end

function M.on_message(self, message_id, message, sender)
	if message.item then
		if message_id == hash("nature") then
			self.pokemon.nature = message.item
			self.pokemon.attributes.nature = natures.get_nature_attributes(message.item)
			gui.set_text(gui.get_node("change_pokemon/txt_nature"), message.item)
			gui.set_color(gui.get_node("change_pokemon/txt_nature"), gui_colors.HERO_TEXT)
		elseif message_id == hash("species") then
			if message.item == "" then
				return
			end
			self.pokemon = _pokemon.new({species=message.item})
			self.abilities = pokedex.get_pokemon_abilities(message.item)
			self.level = self.pokemon.level.current
			self.pokemon.nature = "No Nature"
			local starting_moves = pokedex.get_starting_moves(message.item)
			if #starting_moves > self.move_count then
				starting_moves = utils.shuffle2(starting_moves)
			end
			local moves = {}
			for i=1, self.move_count do
				if starting_moves[i] then
					local pp = movedex.get_move_pp(starting_moves[i])
					moves[starting_moves[i]] = {pp=pp, index=i}
				end
			end
			self.pokemon.moves = moves
			pokemon_image(message.item)
			gui.set_color(gui.get_node("change_pokemon/pokemon_sprite"), vmath.vector4(1))
			gui.set_color(gui.get_node("change_pokemon/species"), gui_colors.TEXT)
			gui.set_text(gui.get_node("change_pokemon/species"), self.pokemon.species.current:upper())
			gui.set_scale(gui.get_node("change_pokemon/species"), vmath.vector3(0.8))
			if self.register_buttons_after_species then self.register_buttons_after_species(self) end
		elseif message_id == hash("evolve") then
			flow.start(function()
				flow.until_true(function() return not monarch.is_busy() end)
				monarch.show("are_you_sure", nil, {title="Evolve at level ".. self.level .. "?", sender=msg.url(), data=message.item})
			end)
		elseif message_id == hash("abilities") then
			table.insert(self.abilities, message.item)
			redraw(self)
		elseif message_id == hash("feats") then
			local count = 0
			table.insert(self.feats, message.item)
			if message.item == "Extra Move" then
				for _, f in pairs(self.feats) do
					if f == "Extra Move" then
						count = count + 1
					end
				end
			end
			self.move_count = 4 + count
			redraw(self)
		else
			if message.item ~= "" then
				local n = move_buttons_list[self.move_button_index].text
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

local function add_feat(self)
	local a = utils.deep_copy(_feats.list)
	monarch.show("scrollist", {}, {items=_feats.list, message_id="feats", sender=msg.url(), title="Pick Feat"})
end

local function delete_ability(self, ability)
	local index
	for i, name in pairs(self.abilities) do
		if name == ability then
			index = i
		end
	end
	table.remove(self.abilities, index)
	redraw(self)
end

local function delete_feat(self, feat)
	local index
	for i, name in pairs(self.feats) do
		if name == feat then
			if name == "Extra Move" then
				local temp_move = {}
				local count = 0
				for move, data in pairs(self.pokemon.moves) do
					count = count + 1
					temp_move[data.index] = move
				end
				self.pokemon.moves[temp_move[count]] = nil
			end
			index = i
		end
	end
	table.remove(self.feats, index)
	redraw(self)
end

local function ability_buttons(self, action_id, action)
	gooey.button("change_pokemon/btn_reset_abilities", action_id, action, function()
		self.abilities = pokedex.get_pokemon_abilities(_pokemon.get_current_species(self.pokemon))
		redraw(self)
	end)
	for _, data in pairs(self.ability_data) do
		if data.name == "Add Other" then
			gooey.button(data.button, action_id, action, function(c) add_ability(self) end)
		else
			gooey.button(data.delete, action_id, action, function(c) delete_ability(self, data.name) end, gooey_buttons.cross_button)
		end
	end
end

local function feats_buttons(self, action_id, action)
	for _, data in pairs(self.feats_data) do
		if data.name == "Add Other" then
			gooey.button(data.button, action_id, action, function() add_feat(self) end)
		else
			gooey.button(data.delete, action_id, action, function(c) delete_feat(self, data.name) end, gooey_buttons.cross_button)
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
	for i, button in pairs(move_buttons_list) do
		gooey.button(button.node, action_id, action, function()
			self.move_button_index = i
			pick_move(self)
		end)
	end
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
	gooey.button("change_pokemon/btn_close", action_id, action, function()
		gameanalytics.addDesignEvent {
			eventId = "Navigation:Back",
			value = monarch.top()
		}
		monarch.back()
	end, gooey_buttons.close_button)
	
	for _, button in pairs(active_buttons) do
		gooey.button(button.node, action_id, action, button.func, button.refresh)
	end

	gooey.button("change_pokemon/asi/btn_collapse", action_id, action, function()
		M.config[hash("change_pokemon/asi/root")].active = not M.config[hash("change_pokemon/asi/root")].active
		if M.config[hash("change_pokemon/asi/root")].active then
			M.config[hash("change_pokemon/moves")].active = false
			M.config[hash("change_pokemon/abilities")].active = false
			M.config[hash("change_pokemon/feats")].active = false
		end
		update_sections()
	end)

	gooey.button("change_pokemon/btn_collapse_moves", action_id, action, function()
		M.config[hash("change_pokemon/moves")].active = not M.config[hash("change_pokemon/moves")].active
		if M.config[hash("change_pokemon/moves")].active then
			M.config[hash("change_pokemon/abilities")].active = false
			M.config[hash("change_pokemon/asi/root")].active = false
			M.config[hash("change_pokemon/feats")].active = false
		end
		update_sections()
	end)

	gooey.button("change_pokemon/btn_collapse_abilities", action_id, action, function()
		M.config[hash("change_pokemon/abilities")].active = not M.config[hash("change_pokemon/abilities")].active
		if M.config[hash("change_pokemon/abilities")].active then
			M.config[hash("change_pokemon/asi/root")].active = false
			M.config[hash("change_pokemon/moves")].active = false
			M.config[hash("change_pokemon/feats")].active = false
		end
		update_sections()
	end)

	gooey.button("change_pokemon/btn_collapse_feats", action_id, action, function()
		M.config[hash("change_pokemon/feats")].active = not M.config[hash("change_pokemon/feats")].active
		if M.config[hash("change_pokemon/feats")].active then
			M.config[hash("change_pokemon/abilities")].active = false
			M.config[hash("change_pokemon/asi/root")].active = false
			M.config[hash("change_pokemon/moves")].active = false
		end
		update_sections()
	end)
	
	if M.config[hash("change_pokemon/abilities")].active then
		ability_buttons(self, action_id, action)
	end
	if M.config[hash("change_pokemon/asi/root")].active then
		attribute_buttons(self, action_id, action)
	end
	if M.config[hash("change_pokemon/moves")].active then
		move_buttons(self, action_id, action)
	end
	if M.config[hash("change_pokemon/extra")].active then
		extra_buttons(self, action_id, action)
	end
	if M.config[hash("change_pokemon/feats")].active then
		feats_buttons(self, action_id, action)
	end
	if M.config[hash("change_pokemon/nature")].active then
		gooey.button("change_pokemon/nature", action_id, action, function()
			monarch.show("scrollist", {}, {items=natures.list, message_id="nature", sender=msg.url(), title="Pick Nature"})
		end)
	end
	
end

return M