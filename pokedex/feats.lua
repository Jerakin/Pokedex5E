local file = require "utils.file"
local utils = require "utils.utils"
local log = require "utils.log"
local fakemon = require "fakemon.fakemon"

local M = {}

local feats

local initialized = false

function M.init()
	if not initialized then
		feats = file.load_json_from_resource("/assets/datafiles/feats.json")
		if fakemon.feats then
			for name, data in pairs(fakemon.feats) do
				feats[name] = data
			end
		end
		M.list = feats.feats
		initialized = true
	end
end


function M.get_feat_description(name)
	if feats[name] then
		return feats[name].Description
	else
		local e = string.format("Can not find Feat: '%s'", tostring(name)) ..  "\n" .. debug.traceback()
		gameanalytics.addErrorEvent {
			severity = "Error",
			message = e
		}
		log.error(e)
		return "This is an error, the app couldn't find the feat"
	end
end

return M