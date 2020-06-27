local defsave = require "defsave.defsave"
local M = {}

local encounters = {}
local active_slot

function M.add(encounter_name, slot)
	slot = slot or 1
	local encounter = {
		slot=slot,
		name=encounter_name,
		seen=0,
		ids={}
	}
	if encounters.slots == nil then
		encounters.slots = {}
	end

	table.insert(encounters.slots, encounter)
	M.save()
	return encounter
end

function M.get_slot(slot)
	if slot ~= nil and #encounters.slots <= slot then
		return encounters.slots[slot]
	end
	return nil
end

function M.update(slot, data)
	for key, value in pairs(data) do
		if not encounters.slots[slot] then
			local e = "Can not find slot '" .. tostring(slot) .. "' in encounter\n" .. debug.traceback()
			gameanalytics.addErrorEvent {
				severity = "Critical",
				message = e
			}
			log.error(e)
		end
		encounters.slots[slot][key] = value
	end
	M.save()
end

function M.delete(slot)
	for index, encounter in pairs(M.get_all_encounters()) do
		if index == slot then
			table.remove(encounters.slots, index)
			break
		end
	end
	M.save()
end

function M.get_all_encounters()
	return encounters.slots or {}
end

function M.set_active(slot)
	active_slot = slot
	encounters.last_used = slot
	M.save()
end

function M.save()
	defsave.set("encounters", "encounters", encounters)
	defsave.save("encounters")
end

function M.get_active()
	return encounters.slots[active_slot]
end

function M.get_active_slot()
	return active_slot
end

function M.get_active_name()
	if encounters.slots[active_slot] then
		return encounters.slots[active_slot].name
	else
		local e = "Can not find active_slot " .. tostring(active_slot) ..  "\n" .. debug.traceback()
		gameanalytics.addErrorEvent {
			severity = "Critical",
			message = e
		}
		log.error(e)
	end
end

function M.get_latest()
	if next(encounters) ~= nil then
		if encounters.last_used ~= nil and encounters.last_used <= #encounters.slots then
			return encounters.last_used
		end
	end
end

local function load_encounters()
	local loaded = defsave.load("encounters")
	encounters = defsave.get("encounters", "encounters")
end

function M.init()
	load_encounters()
	local latest = M.get_latest()
	if latest then
		M.set_active(latest)
	end
end

return M