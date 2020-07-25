local M = {}

local info = sys.get_sys_info()

M.CURRENT = info.system_name
M.MACOS = M.CURRENT == "Darwin"
M.LINUX = M.CURRENT == "Linux"
M.WINDOWS = M.CURRENT == "Windows"
M.ANDROID = M.CURRENT == "Android"
M.IOS = M.CURRENT == "iPhone OS"
M.WEB = M.CURRENT == "HTML5"

M.MOBILE_PHONE = M.ANDROID or M.IOS

return M