local M = {}
local node_id_index = 0

function M.set_id(node)
	local id = "party_nodes_" .. node_id_index
	gui.set_id(node, id)
	node_id_index = node_id_index + 1
	return id
end

function M.join_table(title, T, sep)
	if T then
		return title .. table.concat(T, sep)
	end
	return title
end


function M.add_operation(value)
	if value >= 0 then
		value = "+" .. value
	end
	return value
end

function M.to_mod(v)
	local value = math.floor((v - 10) / 2)
	return add_operation(value)
end

return M