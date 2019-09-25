local screeninfo = require "utils.screeninfo"

local M = {}

function M.get_window_scale()
	local layout_size = vmath.vector3(screeninfo.get_project_width(), screeninfo.get_project_height(), 0)
	local screen_size = vmath.vector3(screeninfo.get_window_width(), screeninfo.get_window_height(), 0)

	local sx, sy = screen_size.x / layout_size.x, screen_size.y / layout_size.y -- scale coef for x and y
	return sx, sy
end

function M.get_scale_coefficients()
	local sx, sy = M.get_window_scale()

	local sx2, sy2 = sx/sy, sy/sx

	local fit = math.min(sx2, sy2) -- Fit scale coefficient 
	return fit, sx2, sy2
end

function M.scale_fit_node_with_stretch(node)
	local fit, sx2, sy2 = M.get_scale_coefficients()
	local node_size = gui.get_size(node) -- Get current size

	node_size.y = (node_size.y/fit) * (1/sx2) -- We divide by fit to cancel the fit transformation and then apply a stretch by multiplying (1/sy)

	gui.set_size(node, node_size)
end

function M.scale_text_to_fit_size(text_node)
	local metrics = gui.get_text_metrics_from_node(text_node)
	local scale = gui.get_scale(text_node)
	local size = gui.get_size(text_node)
	local text_width = scale.x * metrics.width
	local node_width = scale.x * size.x
	if text_width > node_width then
		local new_scale = node_width / text_width
		gui.set_scale(text_node, vmath.vector3(new_scale * scale.x))
	end
end

return M
