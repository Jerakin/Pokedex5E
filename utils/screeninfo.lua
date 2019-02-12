-- Initiate it in your game.render_script by adding this to its init()
-- screeninfo.init(render.get_window_width(), render.get_window_height())

local M = {}

local window_width
local window_height
local project_width
local project_height


function M.init(initial_window_width, initial_window_height)
	window_width = initial_window_width
	window_height = initial_window_height

	project_width = sys.get_config("display.width")
	project_height = sys.get_config("display.height")
end


function M.get_window_width()
	return window_width
end


function M.get_window_height()
	return window_height
end


function M.get_project_width()
	return project_width
end


function M.get_project_height()
	return project_height
end


return M