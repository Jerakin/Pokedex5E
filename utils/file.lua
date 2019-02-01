local log = require "utils.log"

local M = {}

------------------------------------------------------------------------------
function M.load_resource(filename)

	local file = sys.load_resource(filename)
	return file
end

------------------------------------------------------------------------------
function M.load_json_from_resource(filename)
	local file = M.load_resource(filename)
	if file then
		local json_data = nil
		-- Use pcall to catch possible parse errors so that we can print out the name of the file that we failed to parse
		if pcall(function() json_data = json.decode(file) end) then
			return json_data
		else
			assert(nil, "Error parsing json data from file: " .. filename)
			return nil
		end

	end

	log.error("Unable to load json file '" .. filename .. "'")
	return nil
end

return M