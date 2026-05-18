local Test = require("@std/test")

local Transformer = require("../src/transformer")

-- Use @std/test instead

Test.suite("Transformer", function(suite)
	suite:case("Transform", function(check)
		local source = [[
        	local hello = require("@hello/world")
        ]]
		local aliases = {
			["hello"] = "bye",
		}
		local file_paths = {
			["bye/world"] = 'game:GetService("ReplicatedStorage"):WaitForChild("bye"):WaitForChild("world")',
		}

		local transformed = Transformer.transform(source, aliases, file_paths)

		check.neq(source, transformed)
	end)
end)
