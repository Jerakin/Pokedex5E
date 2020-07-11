local M = {}

M.INFO_PLATES = vmath.vector4(253/255, 241/255, 220/255, 1)
M.BACKGROUND = vmath.vector4(240/255, 240/255, 240/255, 1)
M.HERO_TEXT = vmath.vector4(62/255, 62/255, 62/255, 1)
M.HERO_TEXT_FADED = vmath.vector4(112/255, 112/255, 112/255, 0.5)
M.BUTTON_TEXT = vmath.vector4(1, 1, 1, 1)
M.BUTTON_TEXT_DISABLED = vmath.vector4(.5, .5, .5, 1)
M.BUTTON_TEXT_PRESSED = vmath.vector4(236/255, 158/255, 41/255, 1)
M.INACTIVE = vmath.vector4(0.3, 0.3, 0.3, 1)
M.ORANGE = vmath.vector4(236/255, 158/255, 41/255, 1)
M.BLACK = vmath.vector4(0, 0, 0, 1)
M.WHITE = vmath.vector4(1, 1, 1, 1)
M.TEXT = vmath.vector4(38/255, 36/255, 32/255, 1)
M.GREEN = vmath.vector4(3/255, 136/255, 12/255, 1)
M.RED = vmath.vector4(185/255, 48/255, 49/255, 1)
M.SHINY = vmath.vector4(0, 0, 0, 1)

M.HEALTH_TEMPORAY = vmath.vector4(81/255, 194/255, 255/255, 1)
M.HEALTH_MISSING = vmath.vector4(186/255, 186/255, 186/255, 1)
M.HEALTH_ABOVE_MAX = vmath.vector4(0/255, 255/255, 0/255, 1)
M.HEALTH_HEALTHY = vmath.vector4(81/255, 189/255, 62/255, 1)
M.HEALTH_DAMAGED = vmath.vector4(252/255, 255/255, 59/255, 1)
M.HEALTH_CRITICAL = vmath.vector4(255/255, 27/255, 65/255, 1)

return M
