local Transform = require("@transform")
local Process = require("@std/process")
local Path = require("@std/path")
local Luau = require("@std/luau")
local Syntax = require("@std/syntax")
local Query = require("@std/syntax/query")
local Utils = require("@std/syntax/utils")

local Sourcemap = require("@src/sourcemap")

export type AliasesMap = {
	[string]: string,
}

local alias_by_file_path: AliasesMap
local transformer: Transform.Migration = {
	options = {
		{
			kind = "string",
			name = "index_style",
			default = "string", -- "string" | "wait_for_child" | "find_first_child"
		},
	},
	initialize = function(initializeContext: Transform.InitializationContext<{ [any]: any }>)
		local options = initializeContext.options
		local sourcemap = Sourcemap.readSourcemap()

		local index_style = options["index_style"]

		local node_paths = {} :: { [Sourcemap.Sourcemap]: string }
		local aliases_map = {} :: AliasesMap

		local nodes = assert(table.clone(sourcemap.children))

		for _, service in nodes do
			if index_style == "string" then
				node_paths[service] = `@game/{service.name}`
			else
				node_paths[service] = `game:GetService("{service.name}")`
			end
		end

		while next(nodes) do
			local current = assert(table.remove(nodes))
			local children = current.children

			if not children then
				continue
			end

			for _, child in children do
				local name = child.name
				local paths = child.filePaths

				local alias_path = if index_style == "string"
					then `{node_paths[current]}/{name}`
					elseif index_style == "find_first_child" then `{node_paths[current]}:FindFirstChild("{name}")`
					elseif index_style == "wait_for_child" then `{node_paths[current]}:WaitForChild("{name}")`
					else "Unexpected index_style, " .. index_style
				node_paths[child] = alias_path

				if paths then
					for _, path in paths do
						aliases_map[path] = alias_path
					end
				end

				table.insert(nodes, child)
			end
		end

		alias_by_file_path = aliases_map
	end,
	transform = function(context: Transform.Context<{ [any]: any }>)
		local options = context.options

		local index_style = options["index_style"]

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
					local alias_path = alias_by_file_path[formatted_path]

					if alias_path then
						if index_style == "string" then
							return `require("{alias_path}")`
						else
							return `require({alias_path})`
						end
					end
				end

				return nil
			end)

		return replacements
	end,
}

return transformer
