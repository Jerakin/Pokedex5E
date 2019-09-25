local M = {}

local tabs = {moves=1, features=2, traits=3}

local scroll_distance = {[1] = {[1]=0, [2]=0, [3]=0, active=1}, [2] = {moves=0, features=0, traits=0, active=1}}
local active_index = 1
local current_scroll = 0
local _action = vmath.vector3()
local p = vmath.vector3()
local start = vmath.vector3()
local consumed

local old = 0
local max_scroll = 0

function M.set_root_node(index, node)
	scroll_distance[index].node = node
end

function M.reset()
	p.y = 0
	gui.set_position(scroll_distance[active_index].node, p)
end

function M.set_max(page, tab, scroll)
	scroll_distance[page][tab] = math.max(math.abs(scroll)-500, 0)
	pprint(scroll_distance[page])
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
		_action.x = action.x
		_action.y = action.y
		start.x = action.x
		start.y = action.y
	end
	if action_id == hash("touch") then
		if math.abs(start.y - action.y) > 10 then
			old_y = gui.get_position(scroll_distance[active_index].node).y
			max_scroll = scroll_distance[active_index][scroll_distance[active_index].active]
			
			p.y = math.max(p.y - (_action.y-action.y)*0.5, 0) --Don't scroll up

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
	_action.x = action.x
	_action.y = action.y
	return consumed
end


return M