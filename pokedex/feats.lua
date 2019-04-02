local file = require "utils.file"
local utils = require "utils.utils"
local log = require "utils.log"

local M = {}

local feats

local initialized = false

function M.init()
	if not initialized then
		feats = file.load_json_from_resource("/assets/datafiles/feats.json")
		M.list = feats.feats
		initialized = true
	end
end


function M.get_feat_description(name)
	return feats[name].Description
end

return M