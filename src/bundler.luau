local writer = require("@libs/writer")
local TableExt = require("@std/tableext")
local Luau = require("@std/luau")
local Path = require("@std/path")
local Fs = require("@std/fs")
local Syntax = require("@std/syntax")
local Parser = require("@std/syntax/parser")
local Query = require("@std/syntax/query")
local Utils = require("@std/syntax/utils")
local Printer = require("@std/syntax/printer")
local Process = require("@std/process")

local Writer = require("@libs/writer")
local RemoveTypes = require("@src/transformers/remove_types")

local Bundler = {}

local REQUIRE_FUNCTION = "__SNOWLUAU_REQUIRE"
local MODULE_CACHE = "__SNOWLUAU_MODULE_CACHE"
local MODULES = "__SNOWLUAU_MODULES"

local TABLE_DEFINITION_SNIIPET = string.format(
	[[
local %s = {}
local %s = {}
]],
	MODULE_CACHE,
	MODULES
)

local REQUIRE_FUNCTION_SNIPPET = string.format(
	[[
local function %s(requirepath: string, ...): any
    if not %s[requirepath] then
        %s[requirepath] = %s[requirepath](...)
    end

    return %s[requirepath]
end
]],
	REQUIRE_FUNCTION,
	MODULE_CACHE,
	MODULE_CACHE,
	MODULES,
	MODULE_CACHE
)

local function comparePath(a: Path.Path, b: Path.Path)
	return Path.format(Path.normalize(a)) == Path.format(Path.normalize(b))
end

local function removeTypes(source)
	return RemoveTypes.transform({
		path = nil :: any,
		parseresult = Parser.parse(source),
		source = source,
		options = {},
	}) :: string
end

function Bundler.bundle(root: Path.Path): string
	local visited = {}
	local traversal = { root }

	local cwd = Process.cwd()
	local writer = Writer.new()

	writer:append_line("--!nocheck")
	writer:append_line(TABLE_DEFINITION_SNIIPET)
	writer:append_line(REQUIRE_FUNCTION_SNIPPET)

	while next(traversal) do
		local path = assert(table.remove(traversal))
		local exist = TableExt.find(visited, function(visit)
			return comparePath(path, visit)
		end)

		if exist then
			continue
		end

		table.insert(visited, path)
		for _, node in Luau.requires(path) do
			local resolved_path = node.resolvedPath
			if resolved_path then
				table.insert(traversal, Path.parse(resolved_path))
			end
		end
	end

	for _, path in visited do
		local source = Fs.readFileToString(path)
		local context = Parser.parse(removeTypes(source))

		local replacements = Query.findAllFromRoot(context, Utils.isRequireCall)
			:filter(function(cstRequireCall: Syntax.CstExprCall)
				local arguments = cstRequireCall.arguments
				local expression = arguments[1] :: any

				return (#arguments >= 1) and Utils.isExprConstantString(expression) :: any
			end)
			:replace(function(cstRequireCall: Syntax.CstExprCall)
				local arguments = cstRequireCall.arguments
				local expression = arguments[1] :: any

				local value = expression.value
				local text = value.text

				local success, resolved_path = pcall(Luau.resolveModule, text, path)

				if not success then
					return nil
				end

				return `{REQUIRE_FUNCTION}("{Path.format(Path.relative(cwd, resolved_path))}")`
			end)

		local replaced = Printer.printFile(context, replacements)
		local module_name = Path.format(Path.relative(cwd, path))

		writer:append_line(`{MODULES}["{module_name}"] = function(...)`)
		writer:indent()

		writer:append_lines(string.split(replaced, "\n"))

		writer:dedent()
		writer:append_line("end")
	end

	writer:append_line(`return {REQUIRE_FUNCTION}("{Path.format(Path.relative(cwd, root))}", ...)`)

	return writer:finalize()
end

return Bundler
