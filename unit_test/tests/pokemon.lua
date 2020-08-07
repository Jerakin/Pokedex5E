local pokedex = require "pokedex.pokedex"
local pokemon = require "pokedex.pokemon"
local movedex = require "pokedex.moves"
local natures = require "pokedex.natures"
local trainer = require "pokedex.trainer"

return function()
	describe("pokemon.lua", function()
		context("test_pkmn", function()
			test("pkmn_create_new", function()
				local pkmn = pokemon.new({species="Bulbasaur"})
				assert_not_nil(pkmn)
			end)
		end)
		context("test_moves", function()
			test("pkmn_test_tackle", function(t)
				local pkmn = pokemon.new({species="Bulbasaur"})
				
				pokemon.set_current_level(pkmn, 20)
				pokemon.set_attribute(pkmn, "DEX", 2)
				pokemon.set_attribute(pkmn, "STR", -3)
				
				pokemon.set_move(pkmn, "Tackle", 1)
				local tackle = pokemon.get_move_data(pkmn, "Tackle")
				assert_true(tackle.damage == "5d4+2")
				assert_true(tackle.AB == 8)
			end)
			
			test("pkmn_test_razor_leaf", function()
				local pkmn = pokemon.new({species="Bulbasaur"})

				pokemon.set_current_level(pkmn, 20)
				pokemon.set_attribute(pkmn, "DEX", 2)
				pokemon.set_attribute(pkmn, "STR", -3)
				
				pokemon.set_move(pkmn, "Razor Leaf", 1)
				local razor_leaf = pokemon.get_move_data(pkmn, "Razor Leaf")
				assert_true(razor_leaf.damage == "3d10+7")
				assert_true(razor_leaf.AB == 8)
			end)
			
			test("pkmn_test_acid_spray", function()
				local pkmn = pokemon.new({species="Bulbasaur"})

				pokemon.set_current_level(pkmn, 20)
				pokemon.set_attribute(pkmn, "DEX", 2)
				pokemon.set_attribute(pkmn, "STR", -3)

				pokemon.set_move(pkmn, "Acid Spray", 1)

				local acid_spray = pokemon.get_move_data(pkmn, "Acid Spray")
				
				assert_true(acid_spray.damage == "4d6+7")
				assert_true(acid_spray.AB == 8)
				assert_true(acid_spray.save_dc == 16)

			end)
			test("pkmn_test_using_right_ability_bonus_when_zero", function()
				--https://github.com/Jerakin/Pokedex5E/issues/536
				local pkmn = pokemon.new({species="Spinarak"})
				pokemon.set_move(pkmn, "Poison Sting", 1)

				local acid_spray = pokemon.get_move_data(pkmn, "Poison Sting")
				assert_true(acid_spray.damage == "1d4+1")

			end)
		end)
	end)
end