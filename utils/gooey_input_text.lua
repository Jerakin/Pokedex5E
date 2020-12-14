local gooey = require "gooey.gooey"


local function refresh_input(data, input)
	if input.empty and not input.selected then
		gui.set_text(input.node, data.current_text)
	end

	local node_cursor = gui.get_node(data.cursor)
	if input.selected then
		if input.empty then
			gui.set_text(input.node, "")
		end
		gui.set_enabled(node_cursor, true)
		gui.set_position(node_cursor, vmath.vector3(input.total_width*0.5, 0, 0))
		gui.cancel_animation(node_cursor, gui.PROP_COLOR)
		gui.set_color(node_cursor, vmath.vector4(0,0,0,1))
		gui.animate(node_cursor, gui.PROP_COLOR, vmath.vector4(1,1,1,0), gui.EASING_INSINE, 0.8, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
		data.is_enabled = true
	else
		if data.is_enabled then
			data.is_enabled = false
			data.current_text = gui.get_text(input.node)
			data.fn_apply_text(data.current_text)
		end
		gui.set_enabled(node_cursor, false)
		gui.cancel_animation(node_cursor, gui.PROP_COLOR)
	end
end

local INPUT_TEXT = {}

function INPUT_TEXT.on_input(data, action_id, action)
	gooey.input(data.text_field, gui.KEYBOARD_TYPE_DEFAULT, action_id, action, {max_length=data.max_length, allowed_characters=data.allowed_characters, use_marked_text=data.use_marked_text}, function(input)
		refresh_input(data, input)
	end)
end


local M = {}

function M.create(text_field, cursor, initial_text, fn_apply_text, options)
	local data =
	{
		current_text		= initial_text,
		text_field			= text_field,
		cursor				= cursor,
		fn_apply_text 		= fn_apply_text,
		is_enabled			= false,
		max_length			= options.max_length,
		allowed_characters	= options.allowed_characters,
		use_marked_text		= options.use_marked_text,
	}
	
	gui.set_text(gui.get_node(text_field), data.current_text)
	gui.set_enabled(gui.get_node(cursor), false)

	local instance = {}
	for name,fn in pairs(INPUT_TEXT) do
		instance[name] = function(...) return fn(data, ...) end
	end
	return instance
end

return M