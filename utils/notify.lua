local monarch = require "monarch.monarch"
local flow = require "utils.flow"
local M = {}

M.url = nil

M.in_time = 0.5
M.stay_time = 2.5
M.out_time = 0.1

M.MSG_NOTIFY = hash("notify")
M.MSG_DONE = hash("done")

local queue = {}

function M.get_text()
	return queue[1]
end

function M.done()
	msg.post(M.url, M.MSG_DONE)
	table.remove(queue, 1)
	if next(queue) ~= nil then
		msg.post(M.url, M.MSG_NOTIFY)
	end
end

function M.notify(text)
	if #queue < 4 then
		table.insert(queue, text)
		msg.post(M.url, M.MSG_NOTIFY)
	end
end

return M