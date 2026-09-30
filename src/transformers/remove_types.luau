local Transform = require("@transform")
local Query = require("@std/syntax/query")
local Utils = require("@std/syntax/utils")
local Printer = require("@std/syntax/printer")

local transformer: Transform.Migration = {
	transform = function(context: Transform.Context<{ [any]: any }>)
		local replacements = {}
		local removeWithoutTrivia = Utils.replacementWithoutTrivia("")

		Query.findAllFromRoot(context.parseresult, function(cstNode)
			return cstNode
		end):forEach(function(cstNode: any)
			if
				Utils.isType(cstNode)
				or Utils.isTypePack(cstNode)
				or Utils.isStatTypeAlias(cstNode)
				or Utils.isStatTypeFunction(cstNode)
			then
				replacements[cstNode] = replacements[cstNode] or ""
			elseif Utils.isExprTypeAssertion(cstNode) then
				replacements[cstNode.operator] = ""
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

				if cstNode.generics then
					for index, generic in cstNode.generics do
						replacements[generic.name] = removeWithoutTrivia
						if generic.equals then
							replacements[generic.equals] = removeWithoutTrivia
						end
						if generic.default then
							replacements[generic.default] = removeWithoutTrivia
						end
						if cstNode.generics.separators[index] then
							replacements[cstNode.generics.separators[index]] = removeWithoutTrivia
						end
					end
				end

				if cstNode.genericPacks then
					for index, genericPack in cstNode.genericPacks do
						replacements[genericPack.name] = removeWithoutTrivia
						replacements[genericPack.ellipsis] = removeWithoutTrivia
						if genericPack.equals then
							replacements[genericPack.equals] = removeWithoutTrivia
						end
						if genericPack.default then
							replacements[genericPack.default] = removeWithoutTrivia
						end
						if cstNode.genericPacks.separators[index] then
							replacements[cstNode.genericPacks.separators[index]] = removeWithoutTrivia
						end
					end
				end

				if cstNode.openGenerics then
					replacements[cstNode.openGenerics] = removeWithoutTrivia
				end

				if cstNode.closeGenerics then
					replacements[cstNode.closeGenerics] = ""
				end
			elseif Utils.isExprInstantiate(cstNode) then
				replacements[cstNode.leftArrow1] = removeWithoutTrivia
				replacements[cstNode.leftArrow2] = removeWithoutTrivia
				replacements[cstNode.rightArrow1] = removeWithoutTrivia
				replacements[cstNode.rightArrow2] = ""
				for _, argument in cstNode.typeArguments do
					replacements[argument] = removeWithoutTrivia
				end
				for _, separator in cstNode.typeArguments.separators do
					replacements[separator] = removeWithoutTrivia
				end
			end
		end)

		return Printer.printFile(context.parseresult, replacements)
	end,
}

return transformer
