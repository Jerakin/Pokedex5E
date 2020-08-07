local broadcast = require "utils.broadcast"

local latest_local_ip = nil
local latest_global_ip = nil
local is_refreshing_local = false
local is_refreshing_global = false

-- https://forum.defold.com/t/how-to-get-global-ip-address-solved/63597
local GLOBAL_IP_URL = "https://api.ipify.org/?format=json"

local M = {}

M.MSG_IPS_UPDATED = hash("NET_IP_UPDATE")

function M.init()
	M.refresh_local_ip()
end

function M.get_local_ip()
	return latest_local_ip
end

function M.get_global_ip()
	return latest_global_ip
end

function M.refresh_local_ip()
	-- prevent re-entrancy
	if not is_refreshing_local then
		is_refreshing_local = true

		local found_ip = nil
		local local_ip_info = sys.get_ifaddrs()
		for i=1,#local_ip_info do
			local t = local_ip_info[i]
			if t.running and t.up then
				found_ip = t.address
				break
			end
		end

		if found_ip ~= latest_local_ip then
			latest_local_ip = found_ip
			broadcast.send(M.MSG_IPS_UPDATED)
		end

		is_refreshing_local = false
	end
end

function M.refresh_global_ip()
	if not is_refreshing_global then
		is_refreshing_global = true

		http.request(GLOBAL_IP_URL, "GET", function(self, id, res)
			local found_ip = nil
			if res.status == 200 or res.status == 304 then
				found_ip = json.decode(res.response).ip
			end

			if found_ip ~= latest_global_ip then
				latest_global_ip = found_ip
				broadcast.send(M.MSG_IPS_UPDATED)
			end
		
			is_refreshing_global = false
		end)
	end
end

return M