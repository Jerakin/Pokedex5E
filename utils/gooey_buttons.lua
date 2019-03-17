local gui_colors = require "utils.gui_colors"

local M = {}

function M.common_button(button, text_node)
	if button.pressed_now then
		gui.play_flipbook(button.node, hash("common_down"))
		gui.set_color(text_node, gui_colors.BUTTON_TEXT_PRESSED)
	elseif button.released_now then
		gui.play_flipbook(button.node, hash("common_up"))
		gui.set_color(text_node, gui_colors.BUTTON_TEXT)
	elseif not button.pressed and button.out_now then
		gui.play_flipbook(button.node, hash("common_up"))
		gui.set_color(text_node, gui_colors.BUTTON_TEXT)
	end
end

function M.green_button(button)
	if button.pressed_now then
		gui.play_flipbook(button.node, hash("common_green_down"))
	elseif button.released_now then
		gui.play_flipbook(button.node, hash("common_green_up"))
	elseif not button.pressed and button.out_now then
		gui.play_flipbook(button.node, hash("common_green_up"))
	end
end

function M.close_button(button)
	if button.pressed_now then
		gui.play_flipbook(button.node, hash("close_down"))
	elseif button.released_now then
		gui.play_flipbook(button.node, hash("close_up"))
	elseif not button.pressed and button.out_now then
		gui.play_flipbook(button.node, hash("close_up"))
	end
end

function M.edit_button(button)
	if button.pressed_now then
		gui.play_flipbook(button.node, hash("edit_down"))
	elseif button.released_now then
		gui.play_flipbook(button.node, hash("edit_up"))
	elseif not button.pressed and button.out_now then
		gui.play_flipbook(button.node, hash("edit_up"))
	end
end

function M.plus_button(button)
	if button.pressed_now then
		gui.play_flipbook(button.node, hash("plus_down"))
	elseif button.released_now then
		gui.play_flipbook(button.node, hash("plus_up"))
	elseif not button.pressed and button.out_now then
		gui.play_flipbook(button.node, hash("plus_up"))
	end
end

function M.minus_button(button)
	if button.pressed_now then
		gui.play_flipbook(button.node, hash("minus_down"))
	elseif button.released_now then
		gui.play_flipbook(button.node, hash("minus_up"))
	elseif not button.pressed and button.out_now then
		gui.play_flipbook(button.node, hash("minus_up"))
	end
end

local MENU_UP_CLOSED = "menu_up"
local MENU_DOWN_CLOSED = "menu_down"

local MENU_UP_OPEN = "close_up"
local MENU_DOWN_OPEN = "close_down"

local MENU_UP_ACTIVE = MENU_UP_CLOSED
local MENU_DOWN_ACTIVE = MENU_DOWN_CLOSED

function M.set_menu_opened(state)
	if state then
		MENU_UP_ACTIVE = MENU_UP_OPEN
		MENU_DOWN_ACTIVE = MENU_DOWN_OPEN
	else
		MENU_UP_ACTIVE = MENU_UP_CLOSED
		MENU_DOWN_ACTIVE = MENU_DOWN_CLOSED
	end
end

function M.menu_button(button)
	if button.pressed_now then
		gui.play_flipbook(button.node, hash(MENU_DOWN_ACTIVE))
	elseif button.released_now then
		gui.play_flipbook(button.node, hash(MENU_UP_ACTIVE))
	elseif not button.pressed and button.out_now then
		gui.play_flipbook(button.node, hash(MENU_UP_ACTIVE))
	end
end

function M.pokemon_sort_button(button)
	if button.pressed_now then
		gui.play_flipbook(button.node, hash("pokemon_sort_down"))
	elseif button.released_now then
		gui.play_flipbook(button.node, hash("pokemon_sort_up"))
	elseif not button.pressed and button.out_now then
		gui.play_flipbook(button.node, hash("pokemon_sort_up"))
	end
end

function M.pokemon_add_button(button)
	if button.pressed_now then
		gui.play_flipbook(button.node, hash("pokemon_add_down"))
	elseif button.released_now then
		gui.play_flipbook(button.node, hash("pokemon_add_up"))
	elseif not button.pressed and button.out_now then
		gui.play_flipbook(button.node, hash("pokemon_add_up"))
	end
end

return M