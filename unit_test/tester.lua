local deftest = require "deftest.deftest"
local pokedex = require "unit_test.tests.pokedex"
local pokemon = require "unit_test.tests.pokemon"
local trainer = require "unit_test.tests.trainer"

local M = {}

function M.run()
	--deftest.add(pokedex)
	deftest.add(pokemon)
	deftest.add(trainer)
	deftest.run()
end

return M