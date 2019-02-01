local defsave = require "defsave.defsave"

local M = {}

M.storage = {}
M.active = {}

function M.add(pokemon)
	table.insert(M.storage, pokemon)
end

function M.save()
	defsave.set("pokedex5e", "storage", M.storage)
	defsave.set("pokedex5e", "active", M.active)
	defsave.save("pokedex5e")
end

function M.init()
	local loaded = defsave.load("pokedex5e")
	if loaded then
		M.storage = defsave.get("pokedex5e", "storage")
		M.active = defsave.get("pokedex5e", "active")
	end
end

function M.move_to_storage(index)
	local pokemon = table.remove(M.active, index)
	table.insert(M.storage, pokemon)
end

function M.move_to_inventory(index)
	assert(#M.active < 6, "Your party is full")
	local pokemon = table.remove(M.storage, index)
	table.insert(M.active, pokemon)
end

return M