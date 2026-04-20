local Test = require("@std/test")

local Transformer = require("../src/transformer")

-- Use @std/test instead

Test.suite("Transformer", function(suite)
	suite:case("Transform", function(assert)
		local source = [[
            local hello = require("@hello/world")
        ]]

	end)
end)
