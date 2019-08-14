local M = {}

M.os_sep = package.config:sub(1, 1)

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
		local random1 = rnd.range(1, #T)
		local random2 = rnd.range(1, #T)
		T[random1], T[random2] = T[random2], T[random1]
	end
	return T
end

function M.shuffle2(T)
	size = #T
	for i = size, 1, -1 do
		local rand = rnd.range(1, i)
		T[i], T[rand] = T[rand], T[i]
	end
	return T
end

function M.merge(T1, T2)
	local copy = M.shallow_copy(T1)
	for k,v in pairs(T2) do copy[k] = v end
	return copy
end

function M.split(str, sep)
	if sep == nil then
		sep = "%s"
	end
	
	local T={}
	for s in string.gmatch(str, "([^"..sep.."]+)") do
		table.insert(T, s)
	end
	return T
end
	
return M