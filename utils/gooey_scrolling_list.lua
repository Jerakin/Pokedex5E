local gooey = require "gooey.gooey"

local function on_scrolled(data, items, scrollbar)
	if items ~= nil then
		gooey.dynamic_list(data.list_id, data.list_stencil, data.list_item_template, items).scroll_to(0, scrollbar.scroll.y)
	end
end

local function update_list(data, list)
	local scrollbar = gooey.vertical_scrollbar(data.scrollbar_handle, data.scrollbar_bar)
	scrollbar.set_visible(list.max_y and list.max_y > 0)
	scrollbar.scroll_to(0, list.scroll.y)
	
	for i,item in ipairs(list.items) do
		if item.data and item.data ~= "" then
			data.fn_update_item(list, item)
		end
	end

	if data.fn_on_list_update ~= nil then
		data.fn_on_list_update(list)
	end
end

local function update_handle_size(data, list)
	local node_handle = gui.get_node(data.scrollbar_handle)	
	local size_handle = gui.get_size(node_handle)

	local handle_percentage = (list.stencil_size.y / (list.item_size.y * list.data_size))
	if handle_percentage < 1 and handle_percentage > 0 then
		local new_handle_length = handle_percentage * list.stencil_size.y
		new_handle_length = math.ceil(math.max(data.min_handle_length, new_handle_length))

		local length_diff = new_handle_length - size_handle.y		

		if length_diff ~= 0 then
			local node_visual = gui.get_node(data.scrollbar_visual)
			local size_visual = gui.get_size(node_visual)
			local scale_visual = gui.get_scale(node_visual)

			size_visual.y = size_visual.y + (length_diff / scale_visual.y) -- NOTE: only accounting for scaling on visual, as it's the only thing likely to have scaling applied
			size_handle.y = size_handle.y + length_diff

			gui.set_size(node_visual, size_visual)
			gui.set_size(node_handle, size_handle)
		end
	end
end



local SCROLLING_LIST = {}

function SCROLLING_LIST.refresh(data, items, scroll_to_top)
	local list = gooey.dynamic_list(data.list_id, data.list_stencil, data.list_item_template, items)

	if #items == 0 then
		-- Bug in gooey if no items - it was keeping the item.data property around but invalid
		-- https://github.com/britzl/gooey/issues/59
		for i=1,#list.items do
			list.items[i].data = nil
		end		
	end
	
	if scroll_to_top then
		list.scroll_to(0, 0)
	end
	update_list(data, list)
	
	update_handle_size(data, list)	
	local scrollbar = gooey.vertical_scrollbar(data.scrollbar_handle, data.scrollbar_bar)
	scrollbar.set_visible(list.max_y and list.max_y > 0)
	
	if scroll_to_top then
		scrollbar.scroll_to(0, 0)
	end
end

function SCROLLING_LIST.on_input(data, items, action_id, action)
	if next(items) ~= nil then
		local list = gooey.dynamic_list(data.list_id, data.list_stencil, data.list_item_template, items, action_id, action, data.fn_on_item_selected, function(list) update_list(data, list) end)
		
		update_handle_size(data, list)
		if data.allow_scrollbar_input then
			gooey.vertical_scrollbar(data.scrollbar_handle, data.scrollbar_bar, action_id, action, function(scrollbar) on_scrolled(data, items, scrollbar) end)
		end
	end	
end

function SCROLLING_LIST.scroll_to_position(data, items, pos)
	gooey.dynamic_list(data.list_id, data.list_stencil, data.list_item_template, items).scroll_to(0, pos)
	gooey.vertical_scrollbar(data.scrollbar_handle, data.scrollbar_bar).scroll_to(0, pos)
end

function SCROLLING_LIST.scroll_to_start(data, items)	
	SCROLLING_LIST.scroll_to_position(data, items, 0)
end


local M = {}

-- Create an object that can be used to update and handle input for a vertical list.
-- @param list_id Unique identifier for the list
-- @param list_stencil Node string for the list stencil
-- @param list_item_template Node string for the list's item template 
-- @param scrollbar_handle Node string for the scrollbar handle
-- @param scrollbar_bar Node string for the scrollbar background bar
-- @param scrollbar_visual Node string for the scrollbar handle visual
-- @param fn_update_item Function to update an item with its data, will be passed (list, item) info from gooey
-- @param fn_on_item_selected Function to be called when an item is selected, will be passed  (list) info from gooey
-- @param options A set of optional values:
--          min_handle_length - minimum pixels for the handle (integer)
--          allow_scrollbar_input - Whether to allow input on the scrollbar handle (boolean)
--          fn_on_list_update - function to be called when the list updates, passing (list) info from gooey
-- @return An object you can call the SCROLLING_LIST functions called on (minus needing to pass the first "data" param)
function M.create_vertical_dynamic(list_id, list_stencil, list_item_template, scrollbar_handle, scrollbar_bar, scrollbar_visual, fn_update_item, fn_on_item_selected, options)
	local data =
	{
		list_id             = list_id,
		list_stencil        = list_stencil,
		list_item_template  = list_item_template,
		scrollbar_handle    = scrollbar_handle,
		scrollbar_bar       = scrollbar_bar,
		scrollbar_visual    = scrollbar_visual,
		fn_update_item      = fn_update_item,
		fn_on_item_selected = fn_on_item_selected,
		
		allow_scrollbar_input = true,
	}
	
	data.min_handle_length = options and options.min_handle_length or 40
	data.fn_on_list_update = options and options.fn_on_list_update or nil

	if options and options.allow_scrollbar_input ~= nil then
		data.allow_scrollbar_input = options.allow_scrollbar_input
	end

	local instance = {}
	for name,fn in pairs(SCROLLING_LIST) do
		instance[name] = function(...) return fn(data, ...) end
	end
	return instance
end

return M