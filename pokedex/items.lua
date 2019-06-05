local file = require "utils.file"
local utils = require "utils.utils"

local M = {}
local items
local initialized = false


M.other_held = {"Black Belt", "Black Glasses", "Charcoal", "Deep Sea Scale",
"Deep Sea Tooth", "Dragon Fang", "Focus Band", "Hard Stone", "King's Rock",
"Leftovers", "Light Ball", "Lucky Egg", "Lucky Punch", "Magnet", "Metal Coat",
"Metal Powder", "Miracle Seed", "Mystic Water", "NeverMelt Ice", "Pink Bow",
"Poison Barb", "Polkadot Bow", "Quick Claw", "Scope Lens", "Sharp Beak",
"Silver Powder", "Soft Sand", "Spell Tag", "Twisted Spoon"
} 

M.all = {}

M.type_increase = {
	Fighting = "Black Belt",
	Fire = "Charcoal",
	Dark = "Black Glasses",
	Dragon = "Dragon Gang",
	Rock = "Hard Stone",
	Electric = "Magnet",
	Steel = "Metal Cloat",
	Grass = "Miracle Seed",
	Water = "Mystic Water",
	Ice = "NeverMelt Ice",
	Normal = "Pink Bow",
	Poison = "Posion Barb",
	Fairy = "Polkadot Bow",
	Flying = "Sharp Beak",
	Bug = "Silver Powder",
	Ground = "Soft Sand",
	Ghost = "Spell Tag",
	Psychic = "Twisted Spoon"
}

function M.init()
	if not initialized then
		items = file.load_json_from_resource("/assets/datafiles/items.json")
		for name, desc in pairs(items) do
			table.insert(M.all, name)
		end
		
		initialized = true
	else
		local e = "The items have already been initialized"
		gameanalytics.addErrorEvent {
			severity = "Warning",
			message = e
		}
		log.warning(e)
	end
end

function M.get_description(item)
	return items[item].Effect
end

return M