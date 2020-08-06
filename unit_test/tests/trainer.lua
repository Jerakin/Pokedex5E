local pokedex = require "pokedex.pokedex"
local pokemon = require "pokedex.pokemon"
local movedex = require "pokedex.moves"
local natures = require "pokedex.natures"
local trainer = require "pokedex.trainer"

return function()
	describe("trainer.lua", function()
		context("STAB", function()
			before(function() trainer.reset() end)

			test("trainer_STAB_do_not_affect_AB", function(t)
				local pkmn = pokemon.new({species="Bulbasaur"})
				pokemon.set_current_level(pkmn, 20)
				trainer.set_type_master_STAB("Poison", 1)
				trainer.set_STAB("Poison", 1)
				trainer.set_all_levels_STAB(1)
				trainer.set_always_use_STAB("Poison", true)
				
				pokemon.set_move(pkmn, "Tackle", 1)
				local tackle = pokemon.get_move_data(pkmn, "Tackle")
				assert_true(tackle.AB == 7)

				pokemon.set_move(pkmn, "Razor Leaf", 2)
				local razor_leaf = pokemon.get_move_data(pkmn, "Razor Leaf")
				assert_true(razor_leaf.AB == 7)

				pokemon.set_move(pkmn, "Acid Spray", 3)
				local acid_spray = pokemon.get_move_data(pkmn, "Acid Spray")
				assert_true(acid_spray.AB == 7)

				pokemon.set_move(pkmn, "Struggle", 4)
				local struggle = pokemon.get_move_data(pkmn, "Struggle")
				assert_true(struggle.AB == 7)
			end)
			
			test("trainer_STAB", function(t)
				local pkmn = pokemon.new({species="Bulbasaur"})
				pokemon.set_current_level(pkmn, 20)
				trainer.set_type_master_STAB("Poison", 1)

				pokemon.set_move(pkmn, "Tackle", 1)
				local tackle = pokemon.get_move_data(pkmn, "Tackle")
				assert_true(tackle.damage == "5d4+1")

				pokemon.set_move(pkmn, "Razor Leaf", 2)
				local razor_leaf = pokemon.get_move_data(pkmn, "Razor Leaf")
				assert_true(razor_leaf.damage == "3d10+7")
				
				pokemon.set_move(pkmn, "Acid Spray", 3)
				local acid_spray = pokemon.get_move_data(pkmn, "Acid Spray")
				assert_true(acid_spray.damage == "4d6+7")

				pokemon.set_move(pkmn, "Struggle", 4)
				local struggle = pokemon.get_move_data(pkmn, "Struggle")
				assert_true(struggle.damage == "2d1+1")

			end)

			test("trainer_move_STAB", function(t)
				local pkmn = pokemon.new({species="Bulbasaur"})
				pokemon.set_current_level(pkmn, 20)
				trainer.set_STAB("Poison", 1)

				pokemon.set_move(pkmn, "Tackle", 1)
				local tackle = pokemon.get_move_data(pkmn, "Tackle")
				assert_true(tackle.damage == "5d4+1")

				pokemon.set_move(pkmn, "Razor Leaf", 2)
				local razor_leaf = pokemon.get_move_data(pkmn, "Razor Leaf")
				assert_true(razor_leaf.damage == "3d10+6")

				pokemon.set_move(pkmn, "Acid Spray", 3)
				local acid_spray = pokemon.get_move_data(pkmn, "Acid Spray")
				assert_true(acid_spray.damage == "4d6+7")

				pokemon.set_move(pkmn, "Struggle", 4)
				local struggle = pokemon.get_move_data(pkmn, "Struggle")

				assert_true(struggle.damage == "2d1+1")
			end)

			test("trainer_all_level_STAB", function(t)
				local pkmn = pokemon.new({species="Bulbasaur"})
				pokemon.set_current_level(pkmn, 20)
				trainer.set_all_levels_STAB(1)

				pokemon.set_move(pkmn, "Tackle", 1)
				local tackle = pokemon.get_move_data(pkmn, "Tackle")
				assert_true(tackle.damage == "5d4+1")

				pokemon.set_move(pkmn, "Razor Leaf", 2)
				local razor_leaf = pokemon.get_move_data(pkmn, "Razor Leaf")
				assert_true(razor_leaf.damage == "3d10+7")

				pokemon.set_move(pkmn, "Acid Spray", 3)
				local acid_spray = pokemon.get_move_data(pkmn, "Acid Spray")
				assert_true(acid_spray.damage == "4d6+7")

				pokemon.set_move(pkmn, "Struggle", 4)
				local struggle = pokemon.get_move_data(pkmn, "Struggle")
				assert_true(struggle.damage == "2d1+1")
			end)


			test("trainer_always_use_STAB", function(t)
				local pkmn = pokemon.new({species="Bulbasaur"})
				pokemon.set_current_level(pkmn, 20)
				trainer.set_always_use_STAB("Poison", true)

				pokemon.set_move(pkmn, "Tackle", 1)
				local tackle = pokemon.get_move_data(pkmn, "Tackle")
				assert_true(tackle.damage == "5d4+6")

				pokemon.set_move(pkmn, "Razor Leaf", 2)
				local razor_leaf = pokemon.get_move_data(pkmn, "Razor Leaf")
				assert_true(razor_leaf.damage == "3d10+6")

				pokemon.set_move(pkmn, "Acid Spray", 3)
				local acid_spray = pokemon.get_move_data(pkmn, "Acid Spray")
				assert_true(acid_spray.damage == "4d6+6")

				pokemon.set_move(pkmn, "Struggle", 4)
				local struggle = pokemon.get_move_data(pkmn, "Struggle")
				assert_true(struggle.damage == "2d1+1")
			end)

			test("trainer_always_use_STAB_and_move_STAB", function(t)
				local pkmn = pokemon.new({species="Bulbasaur"})
				pokemon.set_current_level(pkmn, 20)
				trainer.set_always_use_STAB("Poison", true)
				trainer.set_STAB("Poison", 1)
				
				pokemon.set_move(pkmn, "Tackle", 1)
				
				local tackle = pokemon.get_move_data(pkmn, "Tackle")
				assert_true(tackle.damage == "5d4+6")
				
				pokemon.set_move(pkmn, "Razor Leaf", 2)
				local razor_leaf = pokemon.get_move_data(pkmn, "Razor Leaf")
				assert_true(razor_leaf.damage == "3d10+6")

				pokemon.set_move(pkmn, "Acid Spray", 3)
				local acid_spray = pokemon.get_move_data(pkmn, "Acid Spray")
				assert_true(acid_spray.damage == "4d6+7")

				pokemon.set_move(pkmn, "Struggle", 4)
				local struggle = pokemon.get_move_data(pkmn, "Struggle")
				assert_true(struggle.damage == "2d1+1")
			end)
			
			test("trainer_always_use_STAB_and_pokemon_STAB", function(t)
				local pkmn = pokemon.new({species="Bulbasaur"})
				pokemon.set_current_level(pkmn, 20)
				trainer.set_always_use_STAB("Poison", true)
				trainer.set_type_master_STAB("Poison", 1)

				pokemon.set_move(pkmn, "Tackle", 1)
				local tackle = pokemon.get_move_data(pkmn, "Tackle")
				assert_true(tackle.damage == "5d4+7")

				pokemon.set_move(pkmn, "Razor Leaf", 2)
				local razor_leaf = pokemon.get_move_data(pkmn, "Razor Leaf")
				assert_true(razor_leaf.damage == "3d10+7")

				pokemon.set_move(pkmn, "Acid Spray", 3)
				local acid_spray = pokemon.get_move_data(pkmn, "Acid Spray")
				assert_true(acid_spray.damage == "4d6+7")
				
				pokemon.set_move(pkmn, "Struggle", 4)
				local struggle = pokemon.get_move_data(pkmn, "Struggle")
				assert_true(struggle.damage == "2d1+1")
			end)
		end)
	end)
end