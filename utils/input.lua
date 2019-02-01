local screen_info = require "utils.screen_info"

local M = {}

local WIDTH = screen_info.RENDER_WIDTH
local HEIGHT = screen_info.RENDER_HEIGHT


function M.scale_action(action)
	local width = tonumber(sys.get_config("display.width"))
	local height = tonumber(sys.get_config("display.height"))
	action.x = (WIDTH / width) * action.x

	action.y = (HEIGHT / height) * action.y
	
	return action
end

return M