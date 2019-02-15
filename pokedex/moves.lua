local type_data = require "utils.type_data"
local file = require "utils.file"
local utils = require "utils.utils"

local M = {}


local movedata
local move_machines

local initialized = false

function M.get_move_data(move)
	return movedata[move]
end


function M.get_move_pp(move)
	return movedata[move] and movedata[move].PP
end


function M.get_move_type(move)
	return M.get_move_data(move).Type
end


function M.get_move_color(move)
	return type_data[M.get_move_type(move)].color
end

function M.get_move_icon(move)
	return type_data[M.get_move_type(move)].icon
end

local function list()
	local l = {}
	for m, d in pairs(movedata) do
		table.insert(l, m)
	end
	return l
end

function M.get_TM(number)
	return move_machines.TM[number]
end
function M.get_HM(number)
	return move_machines.HM[number] 
end

function M.init()
	if not initialized then
		movedata = file.load_json_from_resource("/assets/datafiles/moves.json")
		move_machines = file.load_json_from_resource("/assets/datafiles/move_machines.json")
		M.list = list()
		initialized = true
	end
end
return M