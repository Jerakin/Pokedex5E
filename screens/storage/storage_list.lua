local M = {}

M.list_items = {}
local list_state = {}
local scroll_node
local stencil_node

local start_position
local list_height
local total_height
M.long_press_time = 1
M.TOUCH = hash("touch")


function M.create(stencil, scroll, node_list)
	stencil_node = stencil
	scroll_node = scroll
	M.list_items = node_list
	start_position = gui.get_position(scroll_node)
	M.update(M.list_items)
end

function M.update(node_list)
	M.list_items = node_list
	if next(node_list) == nil then
		return
	end

	-- Clear the list state 
	list_state.out_item_now = nil
	list_state.over_item_now = nil
	list_state.over_item = nil
	list_state.released_item_now = nil
	list_state.pressed_item_now = nil
	list_state.pressed_item = nil
	list_state.selected_item = nil
	local last_item = M.list_items[#M.list_items]
	local item_size = gui.get_size(last_item).y 
	total_height = last_item and (math.abs(gui.get_position(last_item).y) + item_size / 2) or 0
	list_height = gui.get_size(stencil_node).y
	list_state.scroll_pos = vmath.vector3(0)
	list_state.min_y = start_position.y
	list_state.max_y = total_height < list_height and start_position.y or 
	total_height - list_height + start_position.y

end

local function handle_scroll(state)
	local position = gui.get_position(scroll_node)
	if math.abs(state.action.dy) > 60 then
		position.y = position.y + state.action.dy * 10
		position.y = math.min(math.max(position.y, list_state.min_y), list_state.max_y)
		gui.animate(scroll_node, "position", position, gui.EASING_OUTSINE, 0.5)
	else 
		position.y = position.y + (state.action.dy * 0.2)
		position.y = math.min(math.max(position.y, list_state.min_y), list_state.max_y)
		gui.set_position(scroll_node, position)
	end
end

local function handle_input(items, state, action_id, action)
	-- Long press, Press, scroll
	local over_stencil = gui.pick_node(stencil_node, action.x, action.y)
	local touch = action_id == M.TOUCH
	local pressed = touch and action.pressed and over_stencil
	local released = touch and action.released
	local action_pos = vmath.vector3(action.x, action.y, 0)
	if pressed then
		state.pressed_time = socket.gettime()
		state.pressed_pos = action_pos
		state.action_pos = action_pos
		state.long_pressed = false
		state.pressed = true
		gui.cancel_animation(scroll_node, "position")
	elseif released then
		state.pressed = false
		state.scrolling = false
		state.long_pressed = false
	end

	if touch and not pressed and state.selected_item then
		local time = socket.gettime() - state.pressed_time
		if time > M.long_press_time then
			state.long_pressed = true
		end
	else
		state.long_pressed = false
	end
	
	state.action = action
	state.consumed = false
	
	-- handle touch and drag scrolling
	if state.pressed and vmath.length(state.pressed_pos - action_pos) > 10 then
		state.consumed = true
		state.scrolling = true
		state.scroll_pos.y = state.scroll_pos.y + (action_pos.y - state.action_pos.y)
		state.action_pos = action_pos
	end
	-- limit to scroll bounds
	if state.scrolling then
		state.scroll_pos.y = math.min(state.scroll_pos.y, state.max_y)
		state.scroll_pos.y = math.max(state.scroll_pos.y, state.min_y)
		
	end
	-- find which item (if any) that the touch event is over
	local over_item
	for i=1,#items do
		local item = items[i]
		if gui.pick_node(item, action.x, action.y) then
			state.index = i
			state.consumed = true
			over_item = item
			break
		end	
	end

	-- handle list item over state
	state.out_item_now = (state.over_item ~= over_item) and state.over_item or nil
	state.over_item_now = (state.over_item_now ~= state.over_item) and over_item or nil
	state.over_item = over_item

	-- handle list item clicks
	state.released_item_now = nil
	state.pressed_item_now = nil
	if released then
		state.released_item_now = state.pressed_item
		state.pressed_item = nil
	end
	if pressed and state.pressed_item_now ~= over_item then
		state.pressed_item_now = over_item
		state.pressed_item = over_item
	else
		state.pressed_item_now = nil
	end
	if state.released_item_now then
		if not state.scrolling and state.released_item_now == over_item then
			state.selected_item = state.released_item_now
		end
		state.scrolling = false
	end
	return state
end


function M.on_input(action_id, action)
	if M.list_items then
		list_state = handle_input(M.list_items, list_state, action_id, action)
		if list_state.scrolling then
			handle_scroll(list_state)
		end
		
	end
	return list_state
end


return M