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

function M.dump_table(o)
	if type(o) == 'table' then
		local s = '{ '
		for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			s = s .. '['..k..'] = ' .. M.dump_table(v) .. ','
		end
		return s .. '} '
	else
		return tostring(o)
	end
end


local function deep_merge_into_recurse(target, copy_from)
	local changed = false
	for k_copy_from, v_copy_from in pairs(copy_from) do
		local v_target = target[k_copy_from]
		if v_target ~= nil then
			-- Value existed before, verify types match and then replace it
			if type(v_target) == type(v_copy_from) then
				if type(v_target) == 'table' then
					changed = deep_merge_into_recurse(v_target, v_copy_from) or changed
				else
					if v_target ~= v_copy_from then
						target[k_copy_from] = v_copy_from
						changed = true
					end
				end
			end
		else
			-- Value didn't exist before, add it
			if type(v_copy_from) == 'table' then	
				target[k_copy_from] = M.deep_copy(v_copy_from)
			else
				target[k_copy_from] = v_copy_from
			end
			changed = true
		end
	end
	return changed	
end

function M.deep_merge_into(target, copy_from)
	if target ~= nil and copy_from ~= nil and type(target) == 'table' and type(copy_from) == 'table' then
		return deep_merge_into_recurse(target, copy_from)
	end
	return false
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