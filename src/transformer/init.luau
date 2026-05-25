local Query = require("@std/syntax/query")
local Parser = require("@std/syntax/parser")
local Printer = require("@std/syntax/printer")
local Utils = require("@std/syntax/utils")

local Transformer = {}

function Transformer.transform(source: string, aliases: { [string]: string }, file_paths: { [string]: string })
	local parse_result = Parser.parse(source)

	local replacements = Query.findAllFromRoot(parse_result, Utils.isRequireCall):replace(function(astRequireCall)
		local arguments = astRequireCall.arguments

		if #arguments > 1 then
			return
		end

		local expression = arguments[1]
		local node = expression.node
		local token = node.token
		local text = token.text

		if text:sub(1, 1) == "@" then
			local paths = string.split(text, "/")
			paths[1] = aliases[paths[1]:sub(2)]

			local file_path = table.concat(paths, "/")
			local instance_path = file_paths[file_path]

			if not instance_path then
				return
			end

			return `require({instance_path})`
		end

		return
	end)

	return Printer.printFile(parse_result, replacements)
end

return Transformer
