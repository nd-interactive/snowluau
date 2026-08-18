local Transform = require("@transform")
local Syntax = require("@std/syntax")
local Query = require("@std/syntax/query")
local Utils = require("@std/syntax/utils")
local TableExt = require("@std/tableext")

local transformer: Transform.Migration = {
	transform = function(context: Transform.Context<{ [any]: any }>)
		local steps = 0
		local local_names = Query.findAllFromRoot(context.parseresult, Utils.isLocal)
			:replace(function(cstLocal: Syntax.CstLocal)
				steps += 1
				return `v_{string.format("%04d", steps)}`
			end)

		local replacements = {}
		TableExt.combine(
			replacements,
			local_names,
			Query.findAllFromRoot(context.parseresult, Utils.isExprLocal)
				:replace(function(cstExprLocal: Syntax.CstExprLocal)
					return local_names[cstExprLocal["local"]]
				end)
		)

		return replacements
	end,
}

return transformer
