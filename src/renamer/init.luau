local Query = require("@std/syntax/query")
local Parser = require("@std/syntax/parser")
local Printer = require("@std/syntax/printer")
local Utils = require("@std/syntax/utils")
local TableExt = require("@std/tableext")

local Renamer = {}

function Renamer.rename(content: string)
	local cst = Parser.parse(content)


	local steps = 0
	local local_names = Query.findAllFromRoot(cst, Utils.isLocal):replace(function(cstLocal)
		steps += 1
		return `v_{string.format("%04d", steps)}`
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
