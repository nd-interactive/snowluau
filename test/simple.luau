local Assert = require("@std/test/assert")

local Transformer = require("../src/transformer")

-- Use @std/test instead

local source = [[
local a = require("@hello/world")
]]

print(Transformer.transform(source, nil))