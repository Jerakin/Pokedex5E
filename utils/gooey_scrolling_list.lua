local gooey = require "gooey.gooey"

-- This lua file works with the basic vertical list and scrollbar components build into the Pokemon app. It helps set up some of the
-- basic usage of matching up the list with the scrollbar, hiding the scrollbar when it's not needed, and that sort of thing

local M = {}

local function get_scrollbar_handle(str_scrollbar_root)
	local str_handle = "scrollbar/handle"
	if str_scrollbar_root and str_scrollbar_root ~= '' then
		str_handle = str_scrollbar_root .. "/" .. str_handle
	end
	return str_handle
end

local function get_scrollbar_bar(str_scrollbar_root)
	local str_bar = "scrollbar/bar"
	if str_scrollbar_root and str_scrollbar_root ~= '' then
		str_bar = str_scrollbar_root .. "/" .. str_bar
	end
	return str_bar
end

local function on_scrolled(str_list_root, items, scrollbar)
	if items ~= nil then
		gooey.dynamic_list(str_list_root, str_list_root .. "/scroll_area", str_list_root .. "/btn_item", items).scroll_to(0, scrollbar.scroll.y)
	end
end

local function update_list(str_list_root, str_scrollbar_root, update_listitem, list)
	local scrollbar = gooey.vertical_scrollbar(get_scrollbar_handle(str_scrollbar_root), get_scrollbar_bar(str_scrollbar_root))
	scrollbar.set_visible(list.max_y and list.max_y > 0)
	scrollbar.scroll_to(0, list.scroll.y)
	
	for i,item in ipairs(list.items) do
		if item.data and item.data ~= "" then
			update_listitem(list, item)
		end
	end
end

function M.vertical_scrolling_list_refresh(str_list_root, str_scrollbar_root, items, update_listitem, scroll_to_top)
	local list = gooey.dynamic_list(str_list_root, str_list_root .. "/scroll_area", str_list_root .. "/btn_item", items)
	if scroll_to_top then
		list.scroll_to(0, 0)
	end
	update_list(str_list_root, str_scrollbar_root, update_listitem, list)

	local scrollbar = gooey.vertical_scrollbar(get_scrollbar_handle(str_scrollbar_root), get_scrollbar_bar(str_scrollbar_root))
	scrollbar.set_visible(list.max_y and list.max_y > 0)
	
	if scroll_to_top then
		scrollbar.scroll_to(0, 0)
	end
end

function M.vertical_scrolling_list_on_input(str_list_root, str_scrollbar_root, items, action_id, action, update_listitem, on_item_selected)
	if next(items) ~= nil then
		gooey.dynamic_list(str_list_root, str_list_root .. "/scroll_area", str_list_root .. "/btn_item", items, action_id, action, on_item_selected, function(list) update_list(str_list_root, str_scrollbar_root, update_listitem, list) end)
		gooey.vertical_scrollbar(get_scrollbar_handle(str_scrollbar_root), get_scrollbar_bar(str_scrollbar_root), action_id, action, function(scrollbar) on_scrolled(str_list_root, items, scrollbar) end)
	end	
end

return M