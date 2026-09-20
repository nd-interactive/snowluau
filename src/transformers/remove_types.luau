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

				if cstNode.varargAnnotation then
					replacements[cstNode.varargAnnotation] = ""
				end

				if cstNode.returnAnnotation then
					replacements[cstNode.returnAnnotation] = ""
				end

				--[[
				TODO: must remove generic fully.
				if cstNode.generics then
					replacements[cstNode.generics] = ""
				end

				if cstNode.genericPacks then
					replacements[cstNode.genericPacks] = ""
				end

				if cstNode.openGenerics then
					replacements[cstNode.openGenerics] = ""
				end

				if cstNode.closeGenerics then
					replacements[cstNode.closeGenerics] = ""
				end
				]]
			elseif Utils.isExprInstantiate(cstNode) then
				replacements[cstNode] = Printer.printNode(cstNode.expr)
			end
		end)

		return Printer.printFile(context.parseresult, replacements)
	end,
}

return transformer
