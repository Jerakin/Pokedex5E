local gui_utils = require "utils.gui"
local gui_extra_functions = require "gui_extra_functions.gui_extra_functions"
local messages = require "utils.messages"

local M = {}

local scroll_distance = {[1] = {[1]=0, [2]=0, [3]=0, active=1}, [2] = {moves=0, features=0, traits=0, active=1}}
local active_index = 1
local current_scroll = 0
local p = vmath.vector3()
local start = vmath.vector3()
local consumed

local old = 0
local max_scroll = 0

local size_of_scroll_area, sx, sy, sx2, sy2, sc


function M.set_size_of_scroll_area(scroll)
	if sx < sy then
		scroll = scroll * sy2
	end
	size_of_scroll_area = scroll
end

function M.set_root_node(index, node)
	sx, sy = gui_utils.get_window_scale()
	sc, sx2, sy2 = gui_utils.get_scale_coefficients()
	scroll_distance[index].node = node
end

function M.reset()
	p.y = 0
	gui.set_position(scroll_distance[active_index].node, p)
end

function M.set_max(page, tab, scroll)
	if sx < sy then
		scroll = scroll * sc
	end
	scroll_distance[page][tab] = math.max(math.abs(scroll)-size_of_scroll_area, 0)
end

function M.set_active_index(index)
	active_index = index
end

function M.set_active_tab(index, tab)
	scroll_distance[index].active = tab
end

function M.on_input(action_id, action)
	if action.pressed then
		consumed = false
		start.x = action.x
		start.y = action.y
	end
	if action_id == messages.TOUCH then
		if math.abs(start.y - action.y) > 10 then
			old_y = gui.get_position(scroll_distance[active_index].node).y
			max_scroll = scroll_distance[active_index][scroll_distance[active_index].active]
			
			p.y = math.max(p.y + action.dy*0.5, 0) --Don't scroll up

			-- If the old_y position is more than the max scroll than cap the down scroll to the old position
			if max_scroll >= old_y then
				p.y = math.min(p.y, max_scroll)
			else
				p.y = math.min(p.y, old_y)
			end

			gui.set_position(scroll_distance[active_index].node, p)
		end
		if math.abs(start.y - action.y) > 60 then
			consumed = true
		end
	end
	return consumed
end


return M