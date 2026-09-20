local Transform = require("@transform")
local Query = require("@std/syntax/query")
local Utils = require("@std/syntax/utils")
local Printer = require("@std/syntax/printer")

local transformer: Transform.Migration = {
	transform = function(context: Transform.Context<{ [any]: any }>)
		local replacements = {}

		Query.findAllFromRoot(context.parseresult, function(cstNode)
			return cstNode
		end):forEach(function(cstNode: any)
			if Utils.isType(cstNode) or Utils.isStatTypeAlias(cstNode) then
				replacements[cstNode] = ""
			elseif Utils.isExprTypeAssertion(cstNode) then
				replacements[cstNode] = Printer.printNode(cstNode.operand)
			elseif Utils.isLocal(cstNode) then
				local colon = cstNode.colon

				if colon then
					replacements[colon] = ""
				end
			elseif Utils.isExprFunction(cstNode) then
				if cstNode.returnSpecifier then
					replacements[cstNode.returnSpecifier] = ""
				end

				if cstNode.varargColon then
					replacements[cstNode.varargColon] = ""
				end

				if cstNode.returnAnnotation then
					replacements[cstNode.returnAnnotation] = ""
				end
			end
		end)

		return Printer.printFile(context.parseresult, replacements)
	end,
}

return transformer
