local p2p_discovery = require "defnet.p2p_discovery"

local p2p

local M = {}

function M.broadcast()
	p2p = p2p_discovery.create(50000)
	p2p.broadcast("findme")
end

function M.find_broadcast()
	p2p = p2p_discovery.create(50001)
	p2p.listen("findme", function(ip, port)
		print("Found server", ip, port)
	end)
end

function M.update(dt)
	if p2p ~= nul then
		p2p.update()
	end
end

return M