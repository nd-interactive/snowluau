local Fs = require("@std/fs")
local Json = require("@std/json")

local Resolver = {}

function Resolver.resolve()
	local luaurc = Fs.read(assert(Fs.open(".luaurc", "r")))

	print(luaurc)
end

return Resolver
