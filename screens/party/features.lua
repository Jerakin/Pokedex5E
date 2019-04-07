local _pokemon = require "pokedex.pokemon"
local pokedex = require "pokedex.pokedex"
local _feats = require "pokedex.feats"
local gooey = require "gooey.gooey"

local M = {}

local active_ability_lists = {}

local function setup_entry(nodes, name, desc, p, i)
	local root_node
	local name_node
	local desc_node

	if i == 1 then
		root_node = nodes["pokemon/ability/root"]
		name_node = nodes["pokemon/ability/name"]
		desc_node = nodes["pokemon/ability/description"]
		background_node = nodes["pokemon/ability/background"]
	else
		root_node = gui.clone(nodes["pokemon/ability/root"])
		name_node = gui.clone(nodes["pokemon/ability/name"])
		desc_node = gui.clone(nodes["pokemon/ability/description"])
		background_node = gui.clone(nodes["pokemon/ability/background"])
		gui.set_parent(background_node, root_node)
		gui.set_parent(name_node, root_node)
		gui.set_parent(desc_node, root_node)
		gui.set_inherit_alpha(background_node, false)
		gui.set_inherit_alpha(name_node, false)
		gui.set_inherit_alpha(desc_node, false)
	end

	gui.set_position(root_node, p)
	gui.set_text(name_node, name:upper())
	gui.set_text(desc_node, desc)
	local desc_height, name_height = gui.get_text_metrics_from_node(desc_node).height, gui.get_text_metrics_from_node(name_node).height
	local size = gui.get_size(background_node)
	size.y = desc_height + name_height
	gui.set_size(background_node, size)
	local n = gui.get_position(name_node, p)
	local d = gui.get_position(desc_node, p)
	n.y = size.y * 0.55
	d.y = n.y - name_height * 1.2
	gui.set_position(name_node, n)
	gui.set_position(desc_node, d)

	size.y = size.y + 5
	gui.set_size(root_node, size)

	p.y = p.y - desc_height - name_height
	return root_node
end

function M.setup_features(nodes, pokemon)
	local function _setup(list, name, desc, index, p)
		local root_node = setup_entry(nodes, name, desc, p, index)
		local id = list.id .. name
		table.insert(list.data, id)
		gui.set_id(root_node, id)
	end

	active_ability_lists = {}
	local p = vmath.vector3(0, 0, 0)
	local index
	local list = {}
	list.data = {}
	list.id = _pokemon.get_id(pokemon)
	gui.set_id(nodes["pokemon/tab_stencil_2"], list.id .. "tab")
	list.stencil = gui.get_id(nodes["pokemon/tab_stencil_2"])

	local abilities = _pokemon.get_abilities(pokemon)
	local feats = _pokemon.get_feats(pokemon)
	if next(abilities) then
		for i, name in pairs(abilities) do
			index = i
			local desc = pokedex.get_ability_description(name)
			_setup(list, name, desc, index, p)
		end
		table.insert(active_ability_lists, list)
	end
	if next(feats) then
		for i, name in pairs(feats) do
			index = index + 1
			local desc = _feats.get_feat_description(name)
			_setup(list, name, desc, index, p)
		end
		table.insert(active_ability_lists, list)
	end

	if next(abilities) == nil and next(feats) == nil then
		gui.delete_node(nodes["pokemon/ability/root"])
	end
	return active_ability_lists
end

function M.on_input(action_id, action)
	for _, list in pairs(active_ability_lists) do
		if next(list.data) ~= nil then
			gooey.static_list(list.id, list.stencil, list.data, action_id, action, function() end, function() end)
		end
	end
end

return M