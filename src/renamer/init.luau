local Query = require("@std/syntax/query")
local Parser = require("@std/syntax/parser")
local Printer = require("@std/syntax/printer")
local Utils = require("@std/syntax/utils")
local TableExt = require("@std/tableext")

local Renamer = {}

function Renamer.rename(content: string)
	local cst = Parser.parse(content)

	local local_names: { [any]: string } = {}

	local steps = 1
	Query.findAllFromRoot(cst, Utils.isLocal):forEach(function(cstLocal)
		local_names[cstLocal] = `v_{string.format("%04d", steps)}`
		steps += 1
	end)

	local replacements = {}
	TableExt.combine(
		replacements,
		local_names,
		Query.findAllFromRoot(cst, Utils.isExprLocal):replace(function(cstExprLocal)
			return local_names[cstExprLocal["local"]]
		end)
	)

	return Printer.printFile(cst, replacements)
end

return Renamer
