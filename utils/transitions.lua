local transitions = require "monarch.transitions.gui"

local M = {}

function M.default(root_node)
	local transition = transitions.create(root_node)
	.show_in(transitions.slide_in_left, gui.EASING_OUTQUAD, 0.6, 0)
	.show_out(transitions.slide_out_right, gui.EASING_INQUAD, 0.6, 0)
	.back_out(transitions.slide_out_right, gui.EASING_INQUAD, 0.6, 0)
	return transition
end

function M.notification(root_node)
	local transition = transitions.create(root_node)
	.show_in(transitions.slide_in_top, gui.EASING_OUTQUAD, 0.2, 0)
	.show_out(transitions.slide_out_top, gui.EASING_INQUAD, 0.6, 0)
	.back_out(transitions.slide_out_top, gui.EASING_INQUAD, 0.6, 0)
	return transition
end

return M