local file = require "utils.file"
local pokedex = require "pokedex.pokedex"

local profiles = require "pokedex.profiles" -- HACK, SEE USAGE
local fakemon = require "fakemon.fakemon" -- HACK, SEE USAGE

local variant_map = nil
local initialized = false

local M = {}

function M.init()

	if not initialized then
		-- SUPER HACK - profiles is tied into, like, everything. But also it stores the profile's current party, which
		-- needs to be upgraded to use the species/variant system. But since so many things depend on profiles, I can't
		-- tell profiles to depend on variants, because that would be a circular reference.
		-- This is gross but works.
		profiles.register_species_variant_cb(M.get_species_variant_for)

		-- ANOTHER HACK - man, I need to figure out what the dependencies should truly be for this.
		fakemon.register_species_variant_cb(M.get_species_variant_for)

		initialized = true
	end
end


function M.get_species_variant_for(original_name)

	if not variant_map then
		variant_map = {}
		-- Load up the variant mapping file. This goes {species : [var1, var2]} 
		-- Here we change it to {var1: {species: species}, var2: {species: species}}
		local var_map_file = file.load_json_from_resource("/assets/datafiles/variant_map.json")
		for s,v in pairs(var_map_file) do
			for i=1, #v do
				variant_map[v[i]] = {species=s}
			end
		end
	end

	local obj = variant_map[original_name]
	if obj then
		if not obj.variant then
			obj.variant = pokedex.get_variant_from_original_species(obj.species, original_name)
		end
		return obj.species, obj.variant
	end
	return original_name, nil
end

return M