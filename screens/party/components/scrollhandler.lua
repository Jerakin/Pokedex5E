local M = {}


local scroll_distance = {[1] = {distance=0}, [2] = {distance=0}}
local active_index = 1
local current_scroll = 0
local _action = vmath.vector3()
local p = vmath.vector3()
local start = vmath.vector3()
local consumed

function M.set_root_node(index, node)
	scroll_distance[index].node = node
end

function M.reset()
	p.y = 0
	gui.set_position(scroll_distance[active_index].node, p)
end

function M.set_max(page, scroll)
	scroll_distance[page].distance = math.max(scroll_distance[page].distance, math.abs(scroll)-500)
end

function M.set_active_index(index)
	active_index = index
end

function M.on_input(action_id, action)
	if action.pressed then
		consumed = false
		_action.x = action.x
		_action.y = action.y
		start.x = action.x
		start.y = action.y
	end
	if action_id == hash("touch") then
		if math.abs(start.y - action.y) > 10 then
			p.y =  math.min(math.max(p.y - (_action.y-action.y)*0.5, 0), scroll_distance[active_index].distance)
			gui.set_position(scroll_distance[active_index].node, p)
		end
		if math.abs(start.y - action.y) > 60 then
			consumed = true
		end
	end
	_action.x = action.x
	_action.y = action.y
	return consumed
end


return M