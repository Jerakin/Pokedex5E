local monarch = require "monarch.monarch"
local flow = require "utils.flow"
local M = {}

M.url = nil

function M.notify(text)
	collectionfactory.create("")
	flow.start(function()
		monarch.show("notification", {}, {text=text})
	end)
end

return M