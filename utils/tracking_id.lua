local ordered_screens = 
{
	"debug",
	"are_you_sure",
	"info",
	"input",
	"move_info",
	"moves_scrollist",
	"pick_name",
	"random_pokemon",
	"scrollist",
	"sorting",
	"transfer_pokemon",
	"about",
	"add",
	"edit",
	"party",
	"profiles",
	"splash",
	"storage",
	"generate_pokemon",
	"status_effects",
	"import_pokemon",
	"pokedex",
	"settings",
	"fakemon",
	"moves_confirm",
	"network_connect",
	"network_choose_member",
}

local M = {}

function M.init()
	local start_index = 200
	for i=1,#ordered_screens do
		M[hash(ordered_screens[i])] = start_index+i
	end
end

return M