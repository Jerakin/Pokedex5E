local M = {}

-- Menu
M.HIDE = hash("hide")
M.SHOW = hash("show")

-- Defold standard messages
M.ACQUIRE_INPUT_FOCUS = hash("acquire_input_focus")
M.TOUCH = hash("touch")

-- Party messages
M.REFRESH = hash("refresh")
M.RESPONSE = hash("response")
M.UPDATE_EXP = hash("update_exp")
M.UPDATE_HP = hash("update_hp")
M.REFRESH_HP = hash("refresh_hp")
M.UPDATE_TEMP_HP = hash("update_temp_hp")
M.REFRESH_PP = hash("refresh_pp")
M.REFRESH_STATUS = hash("refresh_status")

-- Pokedex
M.MARK = hash("mark")
M.SEARCH = hash("search")

-- Notify
M.NOTIFY = hash("notify")
M.DONE = hash("done")

-- Locations
M.PARTY = "party"
M.PC = "PC"

-- Messages for flow
M.SHOW_PROFILE = hash("show_profile")
M.SHOW_STORAGE = hash("show_storage")
M.SHOW_PARTY = hash("show_party")
M.SHOW_SPLASH = hash("show_splash")


-- Change Pokemon
M.NATURE = hash("nature")
M.SPECIES = hash("species")
M.EVOLVE = hash("evolve")
M.ABILITIES = hash("abilities")
M.FEATS = hash("feats")
M.ITEM = hash("item")
M.MOVE = hash("move")
M.CHANGE_HP = hash("change_hp")
M.RESET = hash("reset")

return M
