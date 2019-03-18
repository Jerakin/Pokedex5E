local monarch = require "monarch.monarch"
local flow = require "utils.flow"
local M = {}

M.url = nil

M.in_time = 0.5
M.stay_time = 2.5
M.out_time = 0.1

local queue = {}

function M.get_text()
	return queue[1]
end

function M.done()
	msg.post(M.url, "done")
	table.remove(queue, 1)
	if next(queue) ~= nil then
		msg.post(M.url, "notify")
	end
end

function M.notify(text)
	table.insert(queue, text)
	msg.post(M.url, "notify")
end

return M