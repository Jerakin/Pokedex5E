-- Copied and adapted from 
-- https://github.com/ToxicFrog/luautil/blob/master/lfs.lua


local windows = package.config:sub(1,1) == "\\"

local other_sep
local sep
local dirsep

if windows then
	sep = '\\'
	other_sep = '/'
	dirsep = ';'
else
	sep = '/'
	dirsep = ':'
end


local function at(s,i)
	return string.sub(s,i,i)
end

--- returns if the path is an absolute path
function lfs.isabs(path)
	if windows then
		return at(path, 1) == '/' or at(path, 1) == '\\' or at(path, 2) ==':'
	else
		return at(path, 1) == '/'
	end
end

-- return the path resulting from combining the individual paths.
-- if the second (or later) path is absolute, we return the last absolute path (joined with any non-absolute paths following).
-- empty elements (except the last) will be ignored.
function lfs.join(path1, path2,...)
	if select('#', ...) > 0 then
		local p = lfs.join(path1, path2)
		local args = {...}
		for i = 1,#args do
			p = lfs.join(p, args[i])
		end
		return p
	end
	if lfs.isabs(path2) then return path2 end
	local endc = at(path1, #path1)
	if endc ~= sep and endc ~= other_sep and endc ~= "" then
		path1 = path1 .. sep
	end
	return path1 .. path2
end

-- Returns the users home directory
function lfs.home()
	local home = os.getenv('HOME')
	if not home then
		home = os.getenv('USERPROFILE') or (os.getenv('HOMEDRIVE') .. os.getenv('HOMEPATH'))
	end
	return home
end

-- We make the simplifying assumption in these functions that path separators
-- are always forward slashes. This is true on *nix and *should* be true on
-- windows, but you can never tell what a user will put into a config file
-- somewhere. This function enforces this.
function lfs.normalize(path)
	if windows then
		return (path:gsub("\\", "/"))
	else
		return path
	end
end

local _attributes = lfs.attributes
function lfs.attributes(path, ...)
	path = lfs.normalize(path)
	if windows then
		-- Windows stat() is kind of awful. If the path has a trailing slash, it
		-- will always fail. Except on drive root directories, which *require* a
		-- trailing slash. Thankfully, appending a "." will always work if the
		-- target is a directory; and if it's not, failing on paths with trailing
		-- slashes is consistent with other OSes.
		path = path:gsub("/$", "/.")
	end

	return _attributes(path, ...)
end

function lfs.exists(path)
	return lfs.attributes(path, "mode") ~= nil
end

function lfs.dirname(oldpath)
	local path = lfs.normalize(oldpath):gsub("[^/]+/*$", "")
	if path == "" then
		return oldpath
	end
	return path
end

function lfs.basename(oldpath)
	local path = lfs.normalize(oldpath):match("[^/]+/*$")
	if path == "" then
		return oldpath
	end
	return path
end

-- Recursive directory creation a la mkdir -p. Unlike lfs.mkdir, this will
-- create missing intermediate directories, and will not fail if the
-- destination directory already exists.
-- It assumes that the directory separator is '/' and that the path is valid
-- for the OS it's running on, e.g. no trailing slashes on windows -- it's up
-- to the caller to ensure this!
function lfs.mkdirs(path)
	path = lfs.normalize(path)
	if lfs.exists(path) then
		return true
	end
	if lfs.dirname(path) == path then
		-- We're being asked to create the root directory!
		return nil,"mkdir: unable to create root directory"
	end
	local r,err = lfs.mkdirs(lfs.dirname(path))
	if not r then
		return nil,err.." (creating "..path..")"
	end
	return lfs.mkdir(path)
end


-- Recursive directory deletion. Unlike lfs.rmdir, this will
-- delete all files recursivly, and will not fail if the
-- directory is not empty.
function lfs.rmdirs(path)
	for file in lfs.dir(path) do
		local file_path = path .. sep .. file
		if file ~= "." and file ~= ".." then
			if lfs.attributes(file_path, 'mode') == 'file' then
				os.remove(file_path)
			elseif lfs.attributes(file_path, 'mode') == 'directory' then
				lfs.rmdirs(file_path)
			end
		end
	end
	return lfs.rmdir(path)
end
