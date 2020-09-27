local defsave = require "defsave.defsave"

local M = {}

M.settings = {}

function M.get(name, default)
	default = default == nil and nil or default
	return M.settings[name] ~= nil and M.settings[name] or default
end

function M.set(name, value)
	M.settings[name] = value
end

function M.save()
	defsave.set("settings", "settings", M.settings)
	defsave.save("settings")
end

function M.load()
	defsave.load("settings")
	M.settings = defsave.get("settings", "settings")
end

return M