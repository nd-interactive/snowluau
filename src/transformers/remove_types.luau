local Transform = require("@transform")
local Syntax = require("@std/syntax")
local Query = require("@std/syntax/query")
local Utils = require("@std/syntax/utils")

type Edit = {
	first: number,
	last: number,
	text: string,
}

local function isTypeDeclaration(node: Syntax.CstNode): boolean
	return Utils.isStatTypeAlias(node) ~= nil or Utils.isStatTypeFunction(node) ~= nil
end

local transformer: Transform.Migration = {
	transform = function(context: Transform.Context<{ [any]: any }>)
		local source = context.source
		local lineOffsets = { 1 }
		for position in string.gmatch(source, "()\n") do
			table.insert(lineOffsets, position + 1)
		end

		-- CST coordinates are one-based byte positions; the end is exclusive.
		local function beginOffset(span: Syntax.Span): number
			return lineOffsets[span.beginLine] + span.beginColumn - 1
		end
		local function endOffset(span: Syntax.Span): number
			return lineOffsets[span.endLine] + span.endColumn - 1
		end

		local edits: { Edit } = {}
		local function insert(position: number, text: string)
			table.insert(edits, { first = position, last = position, text = text })
		end
		local function erase(first: Syntax.Span, last: Syntax.Span?, text: string?)
			local start = beginOffset(first)
			local finish = endOffset(last or first)
			-- Keep line endings and a token boundary, including for `1::number.."x"`.
			local newlines = string.gsub(string.sub(source, start, finish - 1), "[^\r\n]", "")
			table.insert(edits, { first = start, last = finish, text = (text or "") .. " " .. newlines })
		end

		local nodes = Query.findAllFromRoot(context.parseresult, function(node)
			return node
		end).nodes
		for _, node in nodes do
			local binding = Utils.isLocal(node)
			local func = Utils.isExprFunction(node)
			local assertion = Utils.isExprTypeAssertion(node)
			local instantiation = Utils.isExprInstantiate(node)
			if isTypeDeclaration(node) then
				erase(node.location)
			elseif binding then
				if binding.colon and binding.annotation then
					erase(binding.colon.location, binding.annotation.location)
				end
			elseif func then
				if func.openGenerics and func.closeGenerics then
					erase(func.openGenerics.location, func.closeGenerics.location)
				end
				if func.varargColon and func.varargAnnotation then
					erase(func.varargColon.location, func.varargAnnotation.location)
				end
				if func.returnSpecifier and func.returnAnnotation then
					erase(func.returnSpecifier.location, func.returnAnnotation.location)
				end
			elseif assertion then
				-- Assertions produce one value, even when the operand is a call or `...`.
				local operand = assertion.operand
				local instantiated = Utils.isExprInstantiate(operand)
				while instantiated do
					operand = instantiated.expr
					instantiated = Utils.isExprInstantiate(operand)
				end
				local needsParens = Utils.isExprCall(operand) ~= nil or Utils.isExprVarargs(operand) ~= nil
				if needsParens then
					insert(beginOffset(assertion.operand.location), "(")
				end
				erase(assertion.operator.location, assertion.annotation.location, if needsParens then ")" else nil)
			elseif instantiation then
				erase(instantiation.leftArrow1.location, instantiation.rightArrow2.location)
			end
		end

		if #edits == 0 then
			return source
		end

		-- Removing a declaration or assertion can turn the next `(f)()` statement
		-- into a call on the preceding expression. Preserve the parsed boundary.
		for _, node in nodes do
			local block = Utils.isStatBlock(node)
			if block then
				local previous: Syntax.CstStat? = nil
				for _, statement in block.statements do
					if isTypeDeclaration(statement) then
						continue
					end
					local start = beginOffset(statement.location)
					if previous and string.sub(source, start, start) == "(" then
						local finish = endOffset(previous.location)
						if string.sub(source, finish - 1, finish - 1) ~= ";" then
							insert(finish, ";")
						end
					end
					previous = statement
				end
			end
		end

		table.sort(edits, function(a: Edit, b: Edit)
			if a.first ~= b.first then
				return a.first < b.first
			end
			-- Apply insertions before an erasure beginning at the same position.
			if a.last == a.first or b.last == b.first then
				return a.last < b.last
			end
			return a.last > b.last
		end)

		local output = {}
		local cursor = 1
		for _, edit in edits do
			-- An enclosing annotation or declaration also erases all edits inside it.
			if edit.first >= cursor then
				table.insert(output, string.sub(source, cursor, edit.first - 1))
				table.insert(output, edit.text)
				cursor = edit.last
			end
		end
		table.insert(output, string.sub(source, cursor))
		return table.concat(output)
	end,
}

return transformer
