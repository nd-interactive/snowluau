local Transform = require("@transform")
local Process = require("@std/process")
local Path = require("@std/path")
local Luau = require("@std/luau")
local Syntax = require("@std/syntax")
local Query = require("@std/syntax/query")
local Utils = require("@std/syntax/utils")

local Sourcemap = require("@src/sourcemap")

local aliases_map: Sourcemap.AliasesMap
local transformer: Transform.Migration = {
	initialize = function(initializeContext: Transform.InitializationContext<{ [any]: any }>)
		aliases_map = Sourcemap.parseAliasesMap(Sourcemap.readSourcemap())
	end,
	transform = function(context: Transform.Context<{ [any]: any }>)
		assert(aliases_map, "Not initialized.")

		local replacements = Query.findAllFromRoot(context.parseresult, Utils.isRequireCall)
			:replace(function(cstRequireCall: Syntax.CstExprCall)
				local arguments = cstRequireCall.arguments

				if #arguments > 1 then
					return nil
				end

				local expression = arguments[1] :: any

				if not Utils.isExprConstantString(expression) then
					return nil
				end

				local value = expression.value
				local text = value.text

				local success, resolved_path = pcall(Luau.resolveModule, text, context.path)

				if success then
					local cwd_relative_path = Path.relative(Process.cwd(), resolved_path)
					local formatted_path = string.gsub(Path.format(cwd_relative_path), "\\", "/")
					local alias_path = aliases_map[formatted_path]

					if alias_path then
						return `require("{alias_path}")`
					end
				end

				return nil
			end)

		return replacements
	end,
}

return transformer
