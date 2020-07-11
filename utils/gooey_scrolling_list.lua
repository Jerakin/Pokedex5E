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
end



local SCROLLING_LIST = {}

function SCROLLING_LIST.refresh(data, items, scroll_to_top)
	local list = gooey.dynamic_list(data.list_id, data.list_stencil, data.list_item_template, items)
	if scroll_to_top then
		list.scroll_to(0, 0)
	end
	update_list(data, list)

	local scrollbar = gooey.vertical_scrollbar(data.scrollbar_handle, data.scrollbar_bar)
	scrollbar.set_visible(list.max_y and list.max_y > 0)
	
	if scroll_to_top then
		scrollbar.scroll_to(0, 0)
	end
end

function SCROLLING_LIST.on_input(data, items, action_id, action)
	if next(items) ~= nil then
		gooey.dynamic_list(data.list_id, data.list_stencil, data.list_item_template, items, action_id, action, data.fn_on_item_selected, function(list) update_list(data, list) end)
		gooey.vertical_scrollbar(data.scrollbar_handle, data.scrollbar_bar, action_id, action, function(scrollbar) on_scrolled(data, items, scrollbar) end)
	end	
end



local M = {}

-- Return value of create will be able to have the SCROLLING_LIST functions called on it, and will automatically pass the provided data along for the ride
function M.create_vertical_dynamic(list_id, list_stencil, list_item_template, scrollbar_handle, scrollbar_bar, fn_update_item, fn_on_item_selected)
	local data =
	{
		list_id             = list_id,
		list_stencil        = list_stencil,
		list_item_template  = list_item_template,
		scrollbar_handle    = scrollbar_handle,
		scrollbar_bar       = scrollbar_bar,
		fn_update_item      = fn_update_item,
		fn_on_item_selected = fn_on_item_selected,
	}

	-- Populate the return valid with "public" functions from the SCROLLING_LIST table.
	-- This seems to be (sort of) the way gooey does these things, even though it's not really how lua seems
	-- to want to work (unless I'm misunderstanding standards in creating tables and calling functions,
	-- using metatables, and that sort of thing)
	local instance = {}
	for name,fn in pairs(SCROLLING_LIST) do
		instance[name] = function(...) fn(data, ...) end
	end
	return instance
end

return M