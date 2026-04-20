local Syntax = require("@std/syntax")
local Query = require("@std/syntax/query")
local Parser = require("@std/syntax/parser")
local Printer = require("@std/syntax/printer")
local Utils = require("@std/syntax/utils")

local Resolve = require("./resolver")

local Transformer = {}

function Transformer.transform(source: string, configs)
	local parseResult = Parser.parse(source)
	local replacements = Query.findAllFromRoot(parseResult, Utils.isRequireCall)
		:replace(function(requireCall)
			local arguments = requireCall.arguments

			if #arguments > 1 then
				return
			end

			local expression = arguments[1]
			local node = expression.node
			local token = node.token
			local text = token.text

			print(text)

			return `require(route)`
		end)

	return Printer.printFile(parseResult, replacements)
end

return Transformer
