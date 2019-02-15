local M = {}

function M.common_button(button)
	if button.pressed_now then
		gui.play_flipbook(button.node, hash("common_down"))
	elseif button.released_now then
		gui.play_flipbook(button.node, hash("common_up"))
	elseif not button.pressed and button.out_now then
		gui.play_flipbook(button.node, hash("common_up"))
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

function M.menu_button(button)
	if button.pressed_now then
		gui.play_flipbook(button.node, hash("menu_down"))
	elseif button.released_now then
		gui.play_flipbook(button.node, hash("menu_up"))
	elseif not button.pressed and button.out_now then
		gui.play_flipbook(button.node, hash("menu_up"))
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