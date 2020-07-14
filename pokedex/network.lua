local p2p_discovery = require "defnet.p2p_discovery"

local p2p
local version

local function get_broadcast_name()
	return "Pokedex5E-" .. version
end

local M = {}

function M.init()
	local system = sys.get_sys_info().system_name
	if system == "Windows" then
		version = sys.get_config("gameanalytics.build_windows", nil)
	elseif system == "iPhone OS" then
		version = sys.get_config("gameanalytics.build_ios", nil)
	elseif system == "Android" then
		version = sys.get_config("gameanalytics.build_android", nil)
	elseif system == "HTML5" then
		version = sys.get_config("gameanalytics.build_html5", nil)
	end
end

function M.broadcast(port)
	if version ~= nil and p2p == nil then
		p2p = p2p_discovery.create(port)
		p2p.broadcast(get_broadcast_name())
	end
end

function M.find_broadcast(port)
	if version ~= nil and p2p == nil then
		p2p = p2p_discovery.create(port)
		p2p.listen(get_broadcast_name(), function(ip, port)
			print("Found server:", ip, port)
		end)
	end
end

function M.update(dt)
	if p2p ~= nil then
		p2p.update()
	end
end

return M