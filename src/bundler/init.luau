local Luau = require("@std/luau")

local Bundler = {}

for i, v in Luau.requires("cli/init.luau")[1] do
    print(i, v)
end

return Bundler