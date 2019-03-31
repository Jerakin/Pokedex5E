local M = {}

function M.shallow_copy(T)
	local t2 = {}
	for k,v in pairs(T) do
		t2[k] = v
	end
	return t2
end

function M.deep_copy(T)
	local orig_type = type(T)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, T, nil do
			copy[M.deep_copy(orig_key)] = M.deep_copy(orig_value)
		end
		setmetatable(copy, M.deep_copy(getmetatable(T)))
	else -- number, string, boolean, etc
		copy = T
	end
	return copy
end


function M.length(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end


function M.shuffle(T)
	for i = 1, 10 do
		local random1 = math.random(#T)
		local random2 = math.random(#T)
		T[random1], T[random2] = T[random2], T[random1]
	end
	return T
end

function M.shuffle2(tbl)
	size = #tbl
	for i = size, 1, -1 do
		local rand = math.random(i)
		tbl[i], tbl[rand] = tbl[rand], tbl[i]
	end
	return tbl
end

function M.merge(T1, T2)
	local copy = M.shallow_copy(T1)
	for k,v in pairs(T2) do copy[k] = v end
	return copy
end

return M