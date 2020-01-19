local cloud_save = require "utils.cloud_save"
local local_save = require "utils.local_save"

local M = {}

local _save = local_save
local time = 0
if gpgs then
	_save = cloud_save
end

function M.delete(file_name)
	_save.delete(file_name)
end

function M.is_ready()
	return _save.is_ready()
end

function M.update(dt)
	_save.update(dt)
end

function M.load()
	_save.load()
end

function M.load_profile(profile)
	_save.load_profile(profile)
end

function M.init()
	_save.init()
end


function M.commit()
	_save.commit()
end


function M.save()
	_save.save()
end


function M.final()
	_save.final()
end

return M