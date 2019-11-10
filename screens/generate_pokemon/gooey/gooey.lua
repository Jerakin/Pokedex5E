local core = require "gooey.internal.core"
local checkbox = require "gooey.internal.checkbox"
local button = require "gooey.internal.button"
local radio = require "gooey.internal.radio"
local list = require "screens.generate_pokemon.gooey.list"
local input = require "gooey.internal.input"
local scrollbar = require "screens.generate_pokemon.gooey.scrollbar"

local gooey = require "gooey.gooey"

local M = {}

local groups = {}
local current_group = nil


--- Check if a node is enabled. This is done by not only
-- looking at the state of the node itself but also it's
-- ancestors all the way up the hierarchy
-- @param node
-- @return true if node and all ancestors are enabled
function M.is_enabled(node)
	return gooey.is_enabled(node)
end

function M.set_window_size(width, height)
	return gooey.set_window_size(width, height)
end


--- Convenience function to acquire input focus
function M.acquire_input()
	return gooey.acquire_input()
end


--- Convenience function to release input focus
function M.release_input()
	return gooey.release_input()
end


function M.create_theme()
	return gooey.create_theme()
end


--- Mask text by replacing every character with a mask
-- character
-- @param text
-- @param mask
-- @return Masked text
function M.mask_text(text, mask)
	return gooey.mask_text(text, mask)
end


function M.button(node_id, action_id, action, fn, refresh_fn)
	return gooey.button(node_id, action_id, action, fn, refresh_fn)
end


function M.checkbox(node_id, action_id, action, fn, refresh_fn)
	return gooey.checkbox(node_id, action_id, action, fn, refresh_fn)
end


function M.radiogroup(group_id, action_id, action, fn)
	return gooey.radiogroup(group_id, action_id, action, fn)
end


function M.radio(node_id, group_id, action_id, action, fn, refresh_fn)
	return gooey.radio(node_id, group_id, action_id, action, fn, refresh_fn)
end

function M.static_list(list_id, stencil_id, item_ids, action_id, action, fn, refresh_fn, is_horizontal)
	return gooey.static_list(list_id, stencil_id, item_ids, action_id, action, fn, refresh_fn, is_horizontal)
end

function M.list(...)
	return gooey.list(...)
end

function M.horizontal_static_list(list_id, stencil_id, item_ids, action_id, action, fn, refresh_fn)
	return gooey.horizontal_static_list(list_id, stencil_id, item_ids, action_id, action, fn, refresh_fn)
end

function M.vertical_static_list(list_id, stencil_id, item_ids, action_id, action, fn, refresh_fn)
	return gooey.vertical_static_list(list_id, stencil_id, item_ids, action_id, action, fn, refresh_fn)
end

function M.dynamic_list(list_id, stencil_id, item_id, data, action_id, action, fn, refresh_fn, is_horizontal)
	if is_horizontal ~= nil then
		assert(type(is_horizontal) == "boolean", "Provide true for horizontal list or false for vertical list")
	end
	local l = list.dynamic(list_id, stencil_id, item_id, data, action_id, action, fn, refresh_fn, is_horizontal)
	if current_group then
		current_group.components[#current_group.components + 1] = l
	end
	return l
end

function M.horizontal_dynamic_list(list_id, stencil_id, item_id, data, action_id, action, fn, refresh_fn)
	return gooey.horizontal_dynamic_list(list_id, stencil_id, item_id, data, action_id, action, fn, refresh_fn)
end

function M.vertical_dynamic_list(list_id, stencil_id, item_id, data, action_id, action, fn, refresh_fn)
	return M.dynamic_list(list_id, stencil_id, item_id, data, action_id, action, fn, refresh_fn, is_horizontal)
end

function M.vertical_scrollbar(handle_id, bounds_id, action_id, action, fn, refresh_fn)
	local sb = scrollbar.vertical(handle_id, bounds_id, action_id, action, fn, refresh_fn)
	if current_group then
		current_group.components[#current_group.components + 1] = sb
	end
	return sb
end


--- Input text
-- (from dirty larry with modifications)
-- @param node_id Id of a text node
-- @param keyboard_type Keyboard type to use (from gui.KEYBOARD_TYPE_*)
-- @param action_id
-- @param action
-- @param config Optional config table. Accepted values
--  * empty_text (string) - Text to show when the field is empty
--	* max_length (number) - Maximum number of characters that can be entered
--  * allowed_characters (string) - Lua pattern to filter which characters to accept
-- @return Component state
function M.input(node_id, keyboard_type, action_id, action, config, refresh_fn)
	return gooey.input(node_id, keyboard_type, action_id, action, config, refresh_fn)
end


--- A group of components
-- Use this to collect input consume state from multiple components in a convenient way
-- @param id
-- @param fn Interact with gooey components inside this function
-- @return Group state
function M.group(id, fn)
	return gooey.group(id, fn)
end


return M