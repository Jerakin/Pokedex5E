local screeninfo = require "utils.screeninfo"

local M = {}

function M.scale_fit_node_with_stretch(node)
	local layout_size = vmath.vector3(720, 1280, 0) -- layout size
	local screen_size = vmath.vector3(screeninfo.get_window_width(), screeninfo.get_window_height(), 0)
	
	local sx, sy = screen_size.x / layout_size.x, screen_size.y / layout_size.y -- scale coef for  x and y
	local sx2, sy2 = sx/sy, sy/sx
	
	local fit = math.min(sx2, sy2) -- Fit scale coefficient 
	local node_size = gui.get_size(node) -- Get current size
	node_size.y = node_size.y/(fit) * (1/sx2) -- We divide by fit to cancel the fit transformation and then apply a stretch by multiplying (1/sy)

	gui.set_size(node, node_size)
end

function M.scale_text_to_node_size(text_node, box_node)
	local metrics = gui.get_text_metrics_from_node(text_node)
	local box_size = gui.get_size(box_node)
	if metrics.width > box_size.x then
		local scale = box_size/metrics.width
		gui.set_scale(text_node, scale)
	end
end

return M
