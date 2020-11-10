local button = require "utils.button"
local monarch = require "monarch.monarch"
local gooey = require "gooey.gooey"
local natures = require "pokedex.natures"
local _pokemon = require "pokedex.pokemon"
local _feats = require "pokedex.feats"
local items = require "pokedex.items"
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
local gui_utils = require "utils.gui"
local constants = require "utils.constants"
local screens = require "utils.screens"
local messages = require "utils.messages"

local POKEMON_SPECIES_TEXT_SCALE = vmath.vector3(1)

local M = {}

M.block = false

local active_buttons = {}
local move_buttons_list = {}
local button_state = {[true]="minus", [false]="plus"}

M.config = {
	order={
		[1]=hash("change_pokemon/variant"),
		[2]=hash("change_pokemon/nature"),
		[3]=hash("change_pokemon/extra") ,
		[4]=hash("change_pokemon/asi/root"),
		[5]=hash("change_pokemon/moves"),
		[6]=hash("change_pokemon/abilities"),
		[7]=hash("change_pokemon/feats"),
		[8]=hash("change_pokemon/skills"),
		[9]=hash("change_pokemon/held_item"),
		[10]=hash("change_pokemon/custom_asi/root")
	},
	start = vmath.vector3(0, -110, 0),
	[hash("change_pokemon/asi/root")] = {open=vmath.vector3(720, 420, 0), closed=vmath.vector3(720, 85, 0), active=true},
	[hash("change_pokemon/abilities")] = {open=vmath.vector3(720, 200, 0), closed=vmath.vector3(720, 50, 0), active=false},
	[hash("change_pokemon/moves")] = {open=vmath.vector3(720, 0, 0), closed=vmath.vector3(720, 50, 0), active=false},
	[hash("change_pokemon/extra")] = {open=vmath.vector3(720, 150, 0), closed=vmath.vector3(720, 0, 0), active=true},
	[hash("change_pokemon/feats")] = {open=vmath.vector3(720, 200, 0), closed=vmath.vector3(720, 50, 0), active=false},
	[hash("change_pokemon/skills")] = {open=vmath.vector3(720, 200, 0), closed=vmath.vector3(720, 50, 0), active=false},
	[hash("change_pokemon/nature")] = {open=vmath.vector3(720, 70, 0), closed=vmath.vector3(720, 0, 0), active=true},
	[hash("change_pokemon/variant")] = {open=vmath.vector3(720, 70, 0), closed=vmath.vector3(720, 0, 0), active=true},
	[hash("change_pokemon/held_item")] = {open=vmath.vector3(720, 200, 0), closed=vmath.vector3(720, 50, 0), active=false},
	[hash("change_pokemon/custom_asi/root")] = {open=vmath.vector3(720, 420, 0), closed=vmath.vector3(720, 50, 0), active=false}
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
	gui.play_flipbook(gui.get_node("change_pokemon/btn_collapse_skills"), button_state[M.config[hash("change_pokemon/skills")].active])
	gui.play_flipbook(gui.get_node("change_pokemon/btn_collapse_item"), button_state[M.config[hash("change_pokemon/held_item")].active])
	gui.play_flipbook(gui.get_node("change_pokemon/custom_asi/btn_collapse"), button_state[M.config[hash("change_pokemon/custom_asi/root")].active])
	gui.set_enabled(gui.get_node("change_pokemon/btn_reset_abilities"), M.config[hash("change_pokemon/abilities")].active)
end

local function set_gender_icon(self, gender)
	local gender_node = {
		[_pokemon.MALE] = gui.get_node("change_pokemon/male"),
		[_pokemon.FEMALE] = gui.get_node("change_pokemon/female")
	}
	local reverse = {
		[_pokemon.MALE] = _pokemon.FEMALE,
		[_pokemon.FEMALE] = _pokemon.MALE
	}
	local strict = _pokemon.get_strict_gender(self.pokemon)
	local enforce = _pokemon.enforce_genders()

	-- Reset the colors
	gui.set_color(gender_node[_pokemon.MALE], gui_colors.HERO_TEXT)
	gui.set_color(gender_node[_pokemon.FEMALE], gui_colors.HERO_TEXT)

	if gender ~= nil and gender ~= _pokemon.GENDERLESS then
		gui.set_color(gender_node[gender], gui_colors.ORANGE)
	end
	
	if enforce and strict == _pokemon.GENDERLESS then
		-- If the gender is enforced and the strict gender is genderless, disable both buttons
		gui.set_enabled(gender_node[_pokemon.MALE], false)
		gui.set_enabled(gender_node[_pokemon.FEMALE], false)
	elseif enforce and strict ~= _pokemon.ANY then
		-- If the gender is enforced and the strict gender isn't ANY (e.i. not enforced)
		-- Hide the other gender button
		gui.set_enabled(gender_node[reverse[strict]], false)
	end
end

local function set_gender(self, new_gender)
	local gender = _pokemon.get_gender(self.pokemon)
	new_gender = gender ~= new_gender and new_gender or nil
	set_gender_icon(self, new_gender)
	_pokemon.set_gender(self.pokemon, new_gender)
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

local function pokemon_image(species, variant)
	local pokemon_sprite, texture = pokedex.get_icon(species, variant)
	gui.set_texture(gui.get_node("change_pokemon/pokemon_sprite"), texture)
	if pokemon_sprite then 
		gui.play_flipbook(gui.get_node("change_pokemon/pokemon_sprite"), pokemon_sprite)
	end
	gui.set_scale(gui.get_node("change_pokemon/pokemon_sprite"), vmath.vector3(3))
end

local function redraw_list(data_table, entry_table, text_hash, btn_hash, delete_hash, root_hash)
	update_sections()
	for _, entry in pairs(data_table) do
		gui.delete_node(entry.root)
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
		ability_position.y = math.ceil((i-1)/2) * -50
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

	return data_table
end

function M.update_sections()
	update_sections(true)
end

function M.update_hp_counter(self)
	local stored_pokemon = self.pokemon
	local id = _pokemon.get_id(stored_pokemon)
	if storage.is_in_storage(id) then
		stored_pokemon = storage.get_pokemon(id)
	end
	
	local max_hp_node = gui.get_node("change_pokemon/txt_max_hp")
	local mod_hp_node = gui.get_node("change_pokemon/txt_max_hp_mod")
	local old_max = _pokemon.get_total_max_hp(stored_pokemon or self.pokemon)
	local current_max = _pokemon.get_total_max_hp(self.pokemon)
	local extra_hp = current_max - old_max
	if extra_hp == 0 then
		gui.set_enabled(mod_hp_node, false)
	else
		gui.set_enabled(mod_hp_node, true)
	end
	gui.set_text(mod_hp_node, "CHANGED MAX HP: " .. extra_hp)
	gui.set_text(max_hp_node, current_max)
	if extra_hp == 0 then
		gui.set_color(mod_hp_node, gui_colors.TEXT)
	elseif extra_hp >= 1 then
		gui.set_color(mod_hp_node, gui_colors.GREEN)
	else
		gui.set_color(mod_hp_node, gui_colors.RED)
	end
end

local function redraw_moves(self)
	local position = vmath.vector3()
	local _, c = _pokemon.have_feat(self.pokemon, "Extra Move")
	local moves_count = _pokemon.DEFAULT_MAX_MOVES + c

	-- There was a bug with the Extra Moves feat that allowed you to accidentally get moves in slots you should not have been able to get. Preventing a crash, though this does mean you will see more move slots than you SHOULD have
	local moves =_pokemon.get_moves(self.pokemon)
	for _,data in pairs(moves) do
		moves_count = math.max(moves_count, data.index)
	end
	
	M.config[hash("change_pokemon/moves")].open.y = M.config[hash("change_pokemon/moves")].closed.y + math.ceil(moves_count/ 2) * 70

	for _, b in pairs(move_buttons_list) do
		gui.delete_node(gui.get_node(b.node))
	end
	self.move_buttons = {}
	move_buttons_list = {}
	for i=1, moves_count do
		local nodes = gui.clone_tree(self.move_node)
		local txt = nodes["change_pokemon/txt_move"]
		local btn = nodes["change_pokemon/btn_move"]
		local del = nodes["change_pokemon/btn_move_delete"]
		local icon = nodes["change_pokemon/icon_move"]
		gui.set_id(txt, "move_txt" .. i)
		gui.set_id(btn, "move_btn" .. i)
		gui.set_id(del, "delete_move_btn" .. i)
		gui.set_position(btn, position)
		gui.set_enabled(btn, true)
		gui.set_color(txt, gui_colors.HERO_TEXT_FADED)
		table.insert(move_buttons_list, {node="move_btn" .. i, text=txt, icon=icon})
		table.insert(self.move_buttons, {node="delete_move_btn" .. i, text=txt})
		position.x = math.mod(i, 2) * 320
		position.y = math.ceil((i-1)/2) * -70
	end
	for move, data in pairs(moves) do
		local _index = data.index
		local move_node = move_buttons_list[_index].text
		local icon_node = move_buttons_list[_index].icon
		
		move_buttons_list[_index].move_name = move
		gui.set_text(move_node, move:upper())
		gui.set_scale(move_node, vmath.vector3(0.8))
		gui_utils.scale_text_to_fit_size(move_node)
		gui.set_color(move_node, movedex.get_move_color(move))
		gui.play_flipbook(icon_node, movedex.get_move_icon(move))
	end
end

local function update_ASI(self)
	local max_improve_node = gui.get_node("change_pokemon/asi/asi_points")
	local current = _pokemon.get_available_ASI(self.pokemon)
	
	gui.set_text(max_improve_node, current)
	if current == 0 then
		gui.set_color(max_improve_node, gui_colors.TEXT)
	elseif current >= 1 then
		gui.set_color(max_improve_node, gui_colors.GREEN)
	else
		gui.set_color(max_improve_node, gui_colors.RED)
	end
end

local function redraw(self)
	if not self.pokemon then
		print("Why do we redraw now?")
		return
	end
	local id = _pokemon.get_id(self.pokemon)
	local stored_pokemon = self.pokemon
	if storage.is_in_storage(id) then
		stored_pokemon = storage.get_pokemon(id)
	end

	local nickname = _pokemon.get_nickname(self.pokemon)
	local species = _pokemon.get_current_species(self.pokemon)
	nickname = nickname or species:upper()
	gui.set_text(gui.get_node("change_pokemon/species"), nickname)

	gui.set_text(gui.get_node("change_pokemon/txt_level"), _pokemon.get_current_level(self.pokemon))

	gui.set_text(gui.get_node("change_pokemon/txt_nature"), _pokemon.get_nature(self.pokemon):upper())
	gui.set_text(gui.get_node("change_pokemon/txt_hit_dice"), "Hit Dice: d" .. _pokemon.get_hit_dice(self.pokemon))
	gui.set_text(gui.get_node("change_pokemon/pokemon_number"), string.format("#%03d", _pokemon.get_index_number(self.pokemon)))
	gui.set_text(gui.get_node("change_pokemon/txt_item"), (_pokemon.get_held_item(self.pokemon) or "NO ITEM"):upper())

	local variant = _pokemon.get_variant(self.pokemon)
	pokemon_image(species, variant)

	local has_variants = pokedex.has_variants(species)
	local var = _pokemon.get_variant(self.pokemon)
	if has_variants and var then
		gui.set_text(gui.get_node("change_pokemon/txt_variant"), var:upper())
	end
	gui.set_enabled(gui.get_node("change_pokemon/btn_variant"), has_variants)
	
	-- Moves
	redraw_moves(self)

	local function update_ability_score(label_numbers, attributes, scope)
		for _, stat in pairs(constants.ABILITY_LIST) do
			local n = gui.get_node("change_pokemon/".. scope .. "/" .. stat .. "_MOD")
			local stat_num = gui.get_node("change_pokemon/" .. scope .. "/" .. stat)

			gui.set_text(stat_num, label_numbers[stat])
			local mod = ""
			if (attributes[stat] or 0) >= 0 then
				mod = "+"
			end
			if (attributes[stat] or 0) >= 1 then
				gui.set_color(n, gui_colors.GREEN)
				gui.set_color(stat_num, gui_colors.GREEN)
			elseif (attributes[stat] or 0) <= -1 then
				gui.set_color(n, gui_colors.RED)
				gui.set_color(stat_num, gui_colors.RED)
			else
				gui.set_color(n, gui_colors.TEXT)
				gui.set_color(stat_num, gui_colors.TEXT)
			end
			if scope == "asi" then
				gui.set_text(n, "(" .. mod .. (attributes[stat] or 0) ..")")
			end
		end
	end
	
	-- Ability Score Increase
	update_ability_score(_pokemon.get_attributes(self.pokemon), _pokemon.get_increased_attributes(self.pokemon), "asi")

	-- Extra Ability Score
	local custom_attributes = _pokemon.get_custom_attributes(self.pokemon)
	update_ability_score(custom_attributes, custom_attributes, "custom_asi")
	
	-- ASI
	update_ASI(self)

	-- HP
	M.update_hp_counter(self)
	
	-- Abilities
	local root_id = hash("change_pokemon/ability/root")
	local text_id = hash("change_pokemon/ability/txt")
	local btn_id = hash("change_pokemon/ability/btn_entry")
	local del_id = hash("change_pokemon/ability/btn_delete")
	M.config[hash("change_pokemon/abilities")].open.y = M.config[hash("change_pokemon/abilities")].closed.y + math.ceil((#_pokemon.get_abilities(self.pokemon) +1) / 2) * 50
	self.ability_data = redraw_list(self.ability_data, _pokemon.get_abilities(self.pokemon), text_id, btn_id, del_id, root_id)

	-- Feats
	local root_id = hash("change_pokemon/feat/root")
	local text_id = hash("change_pokemon/feat/txt")
	local btn_id = hash("change_pokemon/feat/btn_entry")
	local del_id = hash("change_pokemon/feat/btn_delete")
	M.config[hash("change_pokemon/feats")].open.y = M.config[hash("change_pokemon/feats")].closed.y + math.ceil((#_pokemon.get_feats(self.pokemon) + 1) / 2) * 50
	self.feats_data = redraw_list(self.feats_data, _pokemon.get_feats(self.pokemon), text_id, btn_id, del_id, root_id)

	-- skills
	local root_id = hash("change_pokemon/skill/root")
	local text_id = hash("change_pokemon/skill/txt")
	local btn_id = hash("change_pokemon/skill/btn_entry")
	local del_id = hash("change_pokemon/skill/btn_delete")
	M.config[hash("change_pokemon/skills")].open.y = M.config[hash("change_pokemon/skills")].closed.y + math.ceil((#_pokemon.extra_skills(self.pokemon) + 1) / 2) * 50
	self.skills_data = redraw_list(self.skills_data, _pokemon.extra_skills(self.pokemon), text_id, btn_id, del_id, root_id)
	
	-- level
	local current = _pokemon.get_current_level(self.pokemon)
	gui.set_text(gui.get_node("change_pokemon/txt_level"), current)
	local level_dif = current - _pokemon.get_current_level(stored_pokemon)
	if level_dif == 0 then
		gui.set_text(gui.get_node("change_pokemon/txt_level_mod"), "Lv.")
		gui.set_color(gui.get_node("change_pokemon/txt_level_mod"), gui_colors.TEXT)
	elseif level_dif < 0 then
		gui.set_color(gui.get_node("change_pokemon/txt_level_mod"), gui_colors.RED)
		gui.set_text(gui.get_node("change_pokemon/txt_level_mod"), "Lv. " .. level_dif)
	else
		gui.set_color(gui.get_node("change_pokemon/txt_level_mod"), gui_colors.GREEN)
		gui.set_text(gui.get_node("change_pokemon/txt_level_mod"), "Lv. +" .. level_dif)
	end

	if self.redraw then self.redraw(self) end
end

function M.redraw(self)
	redraw(self)
end

local function custom_increase(self, stat)
	local custom = _pokemon.get_custom_attributes(self.pokemon)
	_pokemon.set_custom_attribute(self.pokemon, stat, custom[stat] + 1)
	redraw(self)
end

local function custom_decrease(self, stat)
	local custom = _pokemon.get_custom_attributes(self.pokemon)
	_pokemon.set_custom_attribute(self.pokemon, stat, custom[stat] - 1)
	redraw(self)
end


local function increase(self, stat)
	local max = _pokemon.get_max_attributes(self.pokemon)
	local added = _pokemon.get_added_attributes(self.pokemon)
	local attributes = pokedex.get_base_attributes(_pokemon.get_caught_species(self.pokemon), _pokemon.get_variant(self.pokemon))
	local nature_attri = natures.get_nature_attributes(_pokemon.get_nature(self.pokemon))
	local increased = _pokemon.get_increased_attributes(self.pokemon)
	local m = attributes[stat] + increased[stat] + (nature_attri[stat] or 0) + added[stat]
	if  m < max[stat] then
		if monarch.top() == screens.ADD then
			_pokemon.set_attribute(self.pokemon, stat, added[stat] + 1)
		else
			_pokemon.set_increased_attribute(self.pokemon, stat, increased[stat] + 1)
		end
		redraw(self)
	end
end

local function decrease(self, stat)
	local added = _pokemon.get_added_attributes(self.pokemon)
	local attributes = pokedex.get_base_attributes(_pokemon.get_caught_species(self.pokemon), _pokemon.get_variant(self.pokemon))
	local increased = _pokemon.get_increased_attributes(self.pokemon)
	local nature_attri = natures.get_nature_attributes(_pokemon.get_nature(self.pokemon))
	local m = attributes[stat] + increased[stat] + (nature_attri[stat] or 0) + added[stat]
	if m > 0 then
		if monarch.top() == screens.ADD then
			_pokemon.set_attribute(self.pokemon, stat, added[stat] - 1)
		else
			_pokemon.set_increased_attribute(self.pokemon, stat, increased[stat] - 1)
		end
		redraw(self)
	end
end

local function pick_move(self)
	self.return_to_screen = monarch.top()
	local move_to_replace = move_buttons_list[self.move_button_index].move_name
	monarch.show(screens.MOVES_SCROLLIST, {}, {species=_pokemon.get_current_species(self.pokemon), level=_pokemon.get_current_level(self.pokemon), pokemon=self.pokemon, current_moves=_pokemon.get_moves(self.pokemon, {append_known_to_all=true}), move_to_replace=move_to_replace, message_id=messages.MOVE, sender=msg.url()})
end

local function refresh_variant_section(self)
	local has_variants = false
	if self.pokemon then
		has_variants = pokedex.has_variants(_pokemon.get_current_species(self.pokemon))
	end
	M.config[hash("change_pokemon/variant")].active = has_variants
end

local function finish_create_flow(self, species, variant)
	M.block = false
	self.choosing_variant_for_new_species = false
	self.pokemon = _pokemon.new({species=species, variant=variant})
	refresh_variant_section(self)

	gui.set_color(gui.get_node("change_pokemon/pokemon_sprite"), vmath.vector4(1))
	gui.set_color(gui.get_node("change_pokemon/species"), gui_colors.TEXT)
	gui.set_text(gui.get_node("change_pokemon/species"), _pokemon.get_current_species(self.pokemon):upper())
	gui_utils.scale_text_to_fit_size(gui.get_node("change_pokemon/species"))
	gui.set_scale(gui.get_node("change_pokemon/species"), POKEMON_SPECIES_TEXT_SCALE)
	local gender = _pokemon.get_gender(self.pokemon)
	set_gender_icon(self, gender)
	if self.register_buttons_after_species then self.register_buttons_after_species(self) end
	
	update_sections(true)
end

function M.init(self, pokemon)
	msg.post(url.MENU, messages.HIDE)

	self.list_items = {}
	self.feats_data = {}
	self.skills_data = {}
	self.move_buttons = {}
	self.ability_data = {}
	self.move_button_index = 0
	self.choosing_variant_for_new_species = false
	self.root = gui.get_node("root")
	gui.set_enabled(gui.get_node("change_pokemon/feat/root"), false)
	gui.set_enabled(gui.get_node("change_pokemon/ability/root"), false)
	gui.set_enabled(gui.get_node("change_pokemon/skill/root"), false)
	gui.set_enabled(gui.get_node("change_pokemon/btn_reset_abilities"), false)
	gui.set_color(gui.get_node("change_pokemon/pokemon_sprite"), vmath.vector4(1))
	gui.set_scale(gui.get_node("change_pokemon/species"), POKEMON_SPECIES_TEXT_SCALE)
	gui_utils.scale_text_to_fit_size(gui.get_node("change_pokemon/species"))
	self.move_node = gui.get_node("change_pokemon/btn_move")
	gui.set_enabled(self.move_node, false)

	if self.pokemon then
		local is_shiny =_pokemon.is_shiny(self.pokemon) or false
		gui.set_enabled(gui.get_node("change_pokemon/checkmark_shiny_mark"), is_shiny)
		gooey.checkbox("change_pokemon/bg_shiny").set_checked(is_shiny)
		gender = _pokemon.get_gender(self.pokemon)
		set_gender_icon(self, gender)
	else
		gui.set_enabled(gui.get_node("change_pokemon/checkmark_shiny_mark"), false)
	end

	refresh_variant_section(self)
	
	update_sections(true)
end

function M.final(self)
	active_buttons = {}
	move_buttons_list = {}
	button.unregister()
end


function M.on_message(self, message_id, message, sender)
	if message.item then
		if message_id == messages.NATURE then
			_pokemon.set_nature(self.pokemon, message.item)
			gui.set_text(gui.get_node("change_pokemon/txt_nature"), message.item)
			gui.set_color(gui.get_node("change_pokemon/txt_nature"), gui_colors.HERO_TEXT)
			M.update_hp_counter(self)
		elseif message_id == messages.SPECIES then
			if message.item == "" then
				return
			end
			self.species = message.item
			local variants = pokedex.get_variants(self.species)
			if not variants or #variants == 0 then
				finish_create_flow(self, self.species, nil)
			else
				-- This pokemon type has variants associated with it
				if pokedex.get_variant_create_mode(self.species) == pokedex.VARIANT_CREATE_MODE_CHOOSE then
					-- User must choose the variant
					self.choosing_variant_for_new_species = true
					flow.start(function()
						flow.until_true(function() return not monarch.is_busy() end)
						monarch.show(screens.SCROLLIST, {}, {items=variants, message_id=messages.VARIANT, sender=msg.url(), title="Choose Variant"})
					end)
				else
					-- Variant is the default
					finish_create_flow(self, self.species, pokedex.get_default_variant(self.species))
				end
			end
		elseif message_id == messages.VARIANT then
			if message.item == "" then
				return
			end

			if self.choosing_variant_for_new_species then
				-- We have not finished creating the pokemon yet after selecting the species. Finish creation
				finish_create_flow(self, self.species, message.item)
			else
				-- We were just changing the variant of an already-chosen pokemon		
				_pokemon.set_variant(self.pokemon, message.item)
				redraw(self)
			end
		elseif message_id == messages.ABILITIES then
			_pokemon.add_ability(self.pokemon, message.item)
		elseif message_id == messages.FEATS then
			_pokemon.add_feat(self.pokemon, message.item)
		elseif message_id == messages.SKILLS then
			_pokemon.add_skill(self.pokemon, message.item)
		elseif message_id == messages.ITEM then
			_pokemon.set_held_item(self.pokemon, message.item)
			gui.set_text(gui.get_node("change_pokemon/txt_item"), message.item:upper())
		elseif message_id == messages.MOVE then
			if message.item ~= "" then
				local n = move_buttons_list[self.move_button_index].text
				_pokemon.set_move(self.pokemon, message.item, self.move_button_index)
				gui.set_text(n, message.item)
				gui.set_color(n, movedex.get_move_color(message.item))
				-- Get out of popups
				monarch.show(self.return_to_screen, {clear=true})
			end
		end
		redraw(self)
	end
	if message_id == messages.RESPONSE and message.response then
		if message.id == messages.CHANGE_HP then
			_pokemon.set_max_hp(self.pokemon, _pokemon.get_max_hp(self.pokemon) + message.data)
			_pokemon.set_max_hp_forced(self.pokemon, true)
			_pokemon.set_current_hp(self.pokemon, _pokemon.get_current_hp(self.pokemon) + message.data)
			M.update_hp_counter(self)
		elseif message.id == messages.RESET then
			local d_max = _pokemon.get_default_max_hp(self.pokemon)
			_pokemon.set_max_hp(self.pokemon, d_max)
			_pokemon.set_max_hp_forced(self.pokemon, false)
			local current = math.min(_pokemon.get_current_hp(self.pokemon), _pokemon.get_total_max_hp(self.pokemon))
			_pokemon.set_current_hp(self.pokemon, current)
			M.update_hp_counter(self)
		end
	end
	gui.set_enabled(self.root, true)
end

local function add_ability(self)
	local a = utils.deep_copy(pokedex.ability_list())
	local filtered = {}
	local add
	for _, new_ability in pairs(a) do 
		add = true
		for _, ability in pairs(_pokemon.get_abilities(self.pokemon)) do
			if new_ability == ability then
				add = false
			end
		end
		if add then
			table.insert(filtered, new_ability)
		end
	end
	monarch.show(screens.SCROLLIST, {}, {items=filtered, message_id=messages.ABILITIES, sender=msg.url(), title="Pick Ability"})
end

local function add_skill(self)
	local skill_list = utils.deep_copy(pokedex.skills)
	local filtered = {}
	local add
	for _, a_skill in pairs(skill_list) do 
		add = true
		for _, skill in pairs(_pokemon.get_skills(self.pokemon)) do
			if a_skill == skill then
				add = false
			end
		end
		if add then
			table.insert(filtered, a_skill)
		end
	end
	monarch.show(screens.SCROLLIST, {}, {items=filtered, message_id=messages.SKILLS, sender=msg.url(), title="Pick Skill"})
end

local function delete_skill(self, skill)
	_pokemon.remove_skill(self.pokemon, skill)
	redraw(self)
end

local function add_feat(self)
	monarch.show(screens.SCROLLIST, {}, {items=_feats.list, message_id=messages.FEATS, sender=msg.url(), title="Pick Feat"})
end

local function delete_ability(self, ability)
	_pokemon.remove_ability(self.pokemon, ability)
	redraw(self)
end

local function delete_feat(self, position)
	_pokemon.remove_feat(self.pokemon, position)
	redraw(self)
end

local function delete_move(self, index)
	_pokemon.remove_move(self.pokemon, index)
	redraw(self)
end

local function ability_buttons(self, action_id, action)
	gooey.button("change_pokemon/btn_reset_abilities", action_id, action, function()
		_pokemon.reset_abilities(self.pokemon)
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
			gooey.button(data.delete, action_id, action, function(c) delete_feat(self, data.position) end, gooey_buttons.cross_button)
		end
	end
end

local function skills_buttons(self, action_id, action)
	for _, data in pairs(self.skills_data) do
		if data.name == "Add Other" then
			gooey.button(data.button, action_id, action, function() add_skill(self) end)
		else
			gooey.button(data.delete, action_id, action, function(c) delete_skill(self, data.position) end, gooey_buttons.cross_button)
		end
	end
end

local function update_shiny_checkbox(checkbox)
	gui.set_enabled(gui.get_node("change_pokemon/checkmark_shiny_mark"), checkbox.checked)
end

local function on_shiny_checked(self, checkbox)
	_pokemon.set_shiny(self.pokemon, checkbox.checked)
end


local function change_level(self, level, multiplier)
	_pokemon.set_current_level(self.pokemon, level + (1 * multiplier))
	
	local con = _pokemon.get_attributes(self.pokemon).CON
	local con_mod = math.floor((con - 10) / 2)
	
	local extra_hp = math.ceil((_pokemon.get_hit_dice(self.pokemon) + 1)/2)
	
	_pokemon.set_max_hp(self.pokemon, _pokemon.get_max_hp(self.pokemon) + extra_hp * multiplier)
	_pokemon.set_current_hp(self.pokemon, _pokemon.get_current_hp(self.pokemon) + (extra_hp + con_mod) * multiplier)
end

local function extra_buttons(self, action_id, action)
	gooey.button("change_pokemon/level/btn_plus", action_id, action, function()
		local level = _pokemon.get_current_level(self.pokemon)
		if level < 20 then
			change_level(self, level, 1)
			redraw(self)
		end 
	end, gooey_buttons.plus_button)

	gooey.button("change_pokemon/level/btn_minus", action_id, action, function()
		local level = _pokemon.get_current_level(self.pokemon)
		if level > 1 and level > pokedex.get_minimum_wild_level(_pokemon.get_current_species(self.pokemon)) then
			change_level(self, level, -1)
			redraw(self)
		end
	end, gooey_buttons.minus_button)

	gooey.checkbox("change_pokemon/bg_shiny", action_id, action, function(checkbox) on_shiny_checked(self, checkbox) end, update_shiny_checkbox)
end

local function move_buttons(self, action_id, action)
	for index, data in pairs(self.move_buttons) do
		local a = gooey.button(data.node, action_id, action, function(c) delete_move(self, index) end, gooey_buttons.cross_button)
		if a.over then
			return
		end
	end
	for i, button in pairs(move_buttons_list) do
		gooey.button(button.node, action_id, action, function()
			self.move_button_index = i
			pick_move(self)
		end)
	end
end

local function attribute_buttons(self, action_id, action, scope, _decrease, _increase)
	gooey.button("change_pokemon/" .. scope .. "/str/btn_minus", action_id, action, function() _decrease(self, "STR") end,gooey_buttons.minus_button)
	gooey.button("change_pokemon/" .. scope .. "/str/btn_plus", action_id, action, function() _increase(self, "STR") end, gooey_buttons.plus_button)
	
	gooey.button("change_pokemon/" .. scope .. "/con/btn_minus", action_id, action, function() 
		_decrease(self, "CON")
		M.update_hp_counter(self)
	end,gooey_buttons.minus_button)
	
	gooey.button("change_pokemon/" .. scope .. "/con/btn_plus", action_id, action, function()
		_increase(self, "CON")
		M.update_hp_counter(self)
	end, gooey_buttons.plus_button)
	
	gooey.button("change_pokemon/" .. scope .. "/dex/btn_minus", action_id, action, function() _decrease(self, "DEX") end,gooey_buttons.minus_button)
	gooey.button("change_pokemon/" .. scope .. "/dex/btn_plus", action_id, action, function() _increase(self, "DEX") end, gooey_buttons.plus_button)
	
	gooey.button("change_pokemon/" .. scope .. "/int/btn_minus", action_id, action, function() _decrease(self, "INT") end,gooey_buttons.minus_button)
	gooey.button("change_pokemon/" .. scope .. "/int/btn_plus", action_id, action, function() _increase(self, "INT") end, gooey_buttons.plus_button)
	
	gooey.button("change_pokemon/" .. scope .. "/wis/btn_minus", action_id, action, function() _decrease(self, "WIS") end, gooey_buttons.minus_button)
	gooey.button("change_pokemon/" .. scope .. "/wis/btn_plus", action_id, action, function() _increase(self, "WIS") end, gooey_buttons.plus_button)
	
	gooey.button("change_pokemon/" .. scope .. "/cha/btn_minus", action_id, action, function() _decrease(self, "CHA") end, gooey_buttons.minus_button)
	gooey.button("change_pokemon/" .. scope .. "/cha/btn_plus", action_id, action, function() _increase(self, "CHA") end, gooey_buttons.plus_button)
end


function M.on_input(self, action_id, action)
	button.on_input(action_id, action)
	gooey.button("change_pokemon/btn_close", action_id, action, function()
		monarch.back()
	end, gooey_buttons.close_button)
	if M.block then
		return
	end
	for _, button in pairs(active_buttons) do
		gooey.button(button.node, action_id, action, button.func, button.refresh)
	end

	gooey.button("change_pokemon/female", action_id, action, function()
		set_gender(self, _pokemon.FEMALE)
	end)
	
	gooey.button("change_pokemon/male", action_id, action, function()
		set_gender(self, _pokemon.MALE)
	end)
	gooey.button("change_pokemon/hp/btn_minus", action_id, action, function()
		if _pokemon.have_ability(self.pokemon, "Paper Thin") then
			monarch.show(screens.INFO, nil, {text="Ability: Paper Thin\nThis Pokemon's max HP is always 1"})
			return
		end
		if _pokemon.get_max_hp_forced(self.pokemon) == true then
			_pokemon.set_current_hp(self.pokemon, _pokemon.get_current_hp(self.pokemon) - 1)
			_pokemon.set_max_hp(self.pokemon, _pokemon.get_max_hp(self.pokemon) - 1)
			M.update_hp_counter(self)
		else
			monarch.show(screens.ARE_YOU_SURE, nil, {title="Are you sure?", text="You will have to track it manually henceforth", sender=msg.url(), data=-1, id=messages.CHANGE_HP})
		end
	end, gooey_buttons.minus_button)

	gooey.button("change_pokemon/hp/btn_plus", action_id, action, function()
		if _pokemon.have_ability(self.pokemon, "Paper Thin") then
			monarch.show(screens.INFO, nil, {text="Ability: Paper Thin\nThis Pokemon's max HP is always 1"})
			return
		end
		if _pokemon.get_max_hp_forced(self.pokemon) then
			_pokemon.set_current_hp(self.pokemon, _pokemon.get_current_hp(self.pokemon) + 1)
			_pokemon.set_max_hp(self.pokemon, _pokemon.get_max_hp(self.pokemon) + 1)
			M.update_hp_counter(self)
		else
			monarch.show(screens.ARE_YOU_SURE, nil, {title="Are you sure?", text="You will have to track it manually henceforth", sender=msg.url(), data=1, id=messages.CHANGE_HP})
		end
	end, gooey_buttons.plus_button)

	gooey.button("change_pokemon/custom_asi/btn_collapse", action_id, action, function()
		M.config[hash("change_pokemon/custom_asi/root")].active = not M.config[hash("change_pokemon/custom_asi/root")].active
		if M.config[hash("change_pokemon/custom_asi/root")].active then
			M.config[hash("change_pokemon/asi/root")].active = false
			M.config[hash("change_pokemon/moves")].active = false
			M.config[hash("change_pokemon/abilities")].active = false
			M.config[hash("change_pokemon/feats")].active = false
			M.config[hash("change_pokemon/skills")].active = false
			M.config[hash("change_pokemon/held_item")].active = false
		end
		update_sections()
	end)
	
	gooey.button("change_pokemon/asi/btn_collapse", action_id, action, function()
		M.config[hash("change_pokemon/asi/root")].active = not M.config[hash("change_pokemon/asi/root")].active
		if M.config[hash("change_pokemon/asi/root")].active then
			M.config[hash("change_pokemon/custom_asi/root")].active = false
			M.config[hash("change_pokemon/moves")].active = false
			M.config[hash("change_pokemon/abilities")].active = false
			M.config[hash("change_pokemon/feats")].active = false
			M.config[hash("change_pokemon/skills")].active = false
			M.config[hash("change_pokemon/held_item")].active = false
		end
		update_sections()
	end)

	gooey.button("change_pokemon/btn_collapse_moves", action_id, action, function()
		M.config[hash("change_pokemon/moves")].active = not M.config[hash("change_pokemon/moves")].active
		if M.config[hash("change_pokemon/moves")].active then
			M.config[hash("change_pokemon/abilities")].active = false
			M.config[hash("change_pokemon/asi/root")].active = false
			M.config[hash("change_pokemon/custom_asi/root")].active = false
			M.config[hash("change_pokemon/feats")].active = false
			M.config[hash("change_pokemon/skills")].active = false
			M.config[hash("change_pokemon/held_item")].active = false
		end
		update_sections()
	end)

	gooey.button("change_pokemon/btn_collapse_abilities", action_id, action, function()
		M.config[hash("change_pokemon/abilities")].active = not M.config[hash("change_pokemon/abilities")].active
		if M.config[hash("change_pokemon/abilities")].active then
			M.config[hash("change_pokemon/asi/root")].active = false
			M.config[hash("change_pokemon/custom_asi/root")].active = false
			M.config[hash("change_pokemon/moves")].active = false
			M.config[hash("change_pokemon/feats")].active = false
			M.config[hash("change_pokemon/skills")].active = false
			M.config[hash("change_pokemon/held_item")].active = false
		end
		update_sections()
	end)

	gooey.button("change_pokemon/btn_collapse_feats", action_id, action, function()
		M.config[hash("change_pokemon/feats")].active = not M.config[hash("change_pokemon/feats")].active
		if M.config[hash("change_pokemon/feats")].active then
			M.config[hash("change_pokemon/skills")].active = false
			M.config[hash("change_pokemon/abilities")].active = false
			M.config[hash("change_pokemon/asi/root")].active = false
			M.config[hash("change_pokemon/custom_asi/root")].active = false
			M.config[hash("change_pokemon/moves")].active = false
			M.config[hash("change_pokemon/held_item")].active = false
		end
		update_sections()
	end)
	
	gooey.button("change_pokemon/btn_collapse_skills", action_id, action, function()
		M.config[hash("change_pokemon/skills")].active = not M.config[hash("change_pokemon/skills")].active
		if M.config[hash("change_pokemon/skills")].active then
			M.config[hash("change_pokemon/feats")].active = false
			M.config[hash("change_pokemon/abilities")].active = false
			M.config[hash("change_pokemon/asi/root")].active = false
			M.config[hash("change_pokemon/custom_asi/root")].active = false
			M.config[hash("change_pokemon/moves")].active = false
			M.config[hash("change_pokemon/held_item")].active = false
		end
		update_sections()
	end)
	
	gooey.button("change_pokemon/btn_collapse_item", action_id, action, function()
		M.config[hash("change_pokemon/held_item")].active = not M.config[hash("change_pokemon/held_item")].active
		if M.config[hash("change_pokemon/held_item")].active then
			M.config[hash("change_pokemon/abilities")].active = false
			M.config[hash("change_pokemon/asi/root")].active = false
			M.config[hash("change_pokemon/custom_asi/root")].active = false
			M.config[hash("change_pokemon/moves")].active = false
			M.config[hash("change_pokemon/feats")].active = false
			M.config[hash("change_pokemon/skills")].active = false
		end
		update_sections()
	end)
	if M.config[hash("change_pokemon/custom_asi/root")].active then
		attribute_buttons(self, action_id, action, "custom_asi", custom_decrease, custom_increase)
	end
	if M.config[hash("change_pokemon/abilities")].active then
		ability_buttons(self, action_id, action)
	end
	if M.config[hash("change_pokemon/asi/root")].active then
		attribute_buttons(self, action_id, action, "asi", decrease, increase)
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
	if M.config[hash("change_pokemon/skills")].active then
		skills_buttons(self, action_id, action)
	end
	if M.config[hash("change_pokemon/nature")].active then
		gooey.button("change_pokemon/btn_nature", action_id, action, function()
			monarch.show(screens.NATURES_SCROLLIST, {}, {items=natures.list, message_id=messages.NATURE, sender=msg.url()})
		end)
	end
	if M.config[hash("change_pokemon/variant")].active then
		gooey.button("change_pokemon/btn_variant", action_id, action, function()
			local variants = pokedex.get_variants(_pokemon.get_current_species(self.pokemon))
			monarch.show(screens.SCROLLIST, {}, {items=variants, message_id=messages.VARIANT, sender=msg.url(), title="Choose Variant"})
		end)
	end
	if M.config[hash("change_pokemon/held_item")].active then
		gooey.button("change_pokemon/btn_item", action_id, action, function()
			monarch.show(screens.SCROLLIST, {}, {items=items.all, message_id=messages.ITEM, sender=msg.url(), title="Pick your Item"})
		end)
		gooey.button("change_pokemon/btn_delete_item", action_id, action, function()
			_pokemon.set_held_item(self.pokemon, nil)
			gui.set_text(gui.get_node("change_pokemon/txt_item"), "NO ITEM")
		end)

	end
end

return M
