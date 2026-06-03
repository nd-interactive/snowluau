local Query = require("@std/syntax/query")
local Parser = require("@std/syntax/parser")
local Printer = require("@std/syntax/printer")
local Utils = require("@std/syntax/utils")
local Luau = require("@std/luau")
local Path = require("@std/path")
local Fs = require("@std/fs")
local Process = require("@std/process")

local Resolver = {}

function Resolver.resolve(input, instance_paths: { [string]: string })
	local source = Fs.readFileToString(input)
	local parse_result = Parser.parse(source)

	local replacements = Query.findAllFromRoot(parse_result, Utils.isRequireCall):replace(function(astRequireCall)
		local arguments = astRequireCall.arguments

		if #arguments > 1 then
			return
		end

		local expression = arguments[1]
		local node = expression.node

		if node.tag ~= "string" then
			return
		end

		local token = node.token
		local text = token.text

		local success, resolved_path = pcall(Luau.resolveModule, text, input)

		if success then
			local relative_resolved =
				assert(string.gsub(Path.format(Path.relative(Process.cwd(), resolved_path)), "\\", "/"))
			local instance_path = instance_paths[relative_resolved]

			if instance_path then
				return `require({instance_path})`
			end
		end

		return
	end)

	return Printer.printFile(parse_result, replacements)
end

return Resolver
