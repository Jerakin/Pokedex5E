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

local function standard_button(button, down, up)
	if button.pressed_now then
		gui.play_flipbook(button.node, down)
	elseif button.released_now then
		gui.play_flipbook(button.node, up)
	elseif not button.pressed and button.out_now then
		gui.play_flipbook(button.node, up)
	end
end

function M.cross_button(button)
	standard_button(button, hash("cross_down"), hash("cross_up"))
end

function M.green_button(button)
	standard_button(button, hash("common_green_down"), hash("common_green_up"))
end

function M.close_button(button)
	standard_button(button, hash("close_down"), hash("close_up"))
end

function M.edit_button(button)
	standard_button(button, hash("edit_down"), hash("edit_up"))
end

function M.plus_button(button)
	standard_button(button, hash("plus_down"), hash("plus_up"))
end

function M.minus_button(button)
	standard_button(button, hash("minus_down"), hash("minus_up"))
end

function M.clipboard_share(button)
	standard_button(button, hash("share_clipboard_down"), hash("share_clipboard_up"))
end

function M.qr_share(button)
	standard_button(button, hash("share_qr_down"), hash("share_qr_up"))
end

function M.network_share(button)
	standard_button(button, hash("share_network_down"), hash("share_network_up"))
end

function M.pokemon_sort_button(button)
	standard_button(button, hash("pokemon_sort_down"), hash("pokemon_sort_up"))
end

function M.pokemon_add_button(button)
	standard_button(button, hash("pokemon_add_down"), hash("pokemon_add_up"))
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
	standard_button(button, hash(MENU_DOWN_ACTIVE), hash(MENU_UP_ACTIVE))
end

return M