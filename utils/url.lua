-- function foo()
--   msg.post(url.background, "foobar")
-- end
--
-- -- Function syntax: 
-- function init(self)
--   url.set("background", msg.url("."))
-- end
--
--
-- function foo()
--   msg.post(url.get("background"), "foobar")
-- end
--

local M = {}

local urls = {}

local url_metatable = {
	__index = function (table, key)
		local tag_hash = key
		if type(key) == "string" then
			tag_hash = hash(key)
		end
		return urls[tag_hash]
	end,

	__newindex = function (table, key, value)
		local tag_hash = key
		if type(key) == "string" then
			tag_hash = hash(key)
		end

		urls[tag_hash] = value
	end
}

function M.set(tag, url)
	M[tag] = url
end

function M.get(tag)
	return M[tag]
end

setmetatable(M, url_metatable)

return M