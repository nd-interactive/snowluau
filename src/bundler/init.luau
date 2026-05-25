local Fs = require("@std/fs")
local Path = require("@std/path")
local Process = require("@std/process")

local Luau = require("@std/luau")
local Query = require("@std/syntax/query")
local Parser = require("@std/syntax/parser")
local Printer = require("@std/syntax/printer")
local Utils = require("@std/syntax/utils")

local Writer = require("./writer")

local Bundler = {}

local MODULES_NAME = "__SNOWLUAU_MODULES"
local CACHES_NAME = "__SNOWLUAU_CACHES"
local CACHE_FUNCTION_NAME = "__SNOWLUAU_CACHE_FUNCTION"

local function read_module(path)
	local path_type = Fs.type(path)

	if path_type == "dir" then
		local init_luau = Path.join(path, "init.luau")
		local init_lua = Path.join(path, "init.lua")

		return Fs.exists(init_luau) and init_luau or Fs.exists(init_lua) and init_lua
	elseif path_type == "file" then
		return path
	end

	return
end

function Bundler.bundle(entry: string)
	local writer = Writer.new()

	writer:append_line(`local {MODULES_NAME} = \{}`)
	writer:append_line(`local {CACHES_NAME} = \{}`)
	writer:append("\n")

	writer:append_line(`local function {CACHE_FUNCTION_NAME}(path: string)`)
	writer:indent()

	writer:append_line(`local func = {MODULES_NAME}[path]`)
	writer:append_line(`local cache = {CACHES_NAME}[path]`)
	writer:append("\n")
	writer:append_line("if not cache then")
	writer:indent()

	writer:append_line("cache = func()")
	writer:append_line(`{CACHES_NAME}[path] = cache`)
	writer:dedent()

	writer:append_line("end")
	writer:append("\n")
	writer:append_line("return cache")

	writer:dedent()
	writer:append_line("end")
	writer:append("\n")

	local entry_absolute = Path.resolve(entry)
	local entry_cwd_relative = read_module(entry)

	local modules = {}
	local paths = { entry_cwd_relative }

	while next(paths) do
		local path = Path.format(table.remove(paths))
		local path_context = Fs.readFileToString(path)

		for _, child in Luau.requires(path) do
			if child.resolvedPath then
				local child_name = Path.format(Path.relative(entry_absolute, child.resolvedPath))

				if not modules[child_name] then
					local parse_result = Parser.parse(path_context)

					local replacements = Query.findAllFromRoot(parse_result, Utils.isRequireCall)
						:replace(function(astRequireCall)
							local arguments = astRequireCall.arguments

							if #arguments > 1 then
								return
							end

							local expression = arguments[1]
							local node = expression.node
							local token = node.token
							local text = token.text

							if string.sub(text, 1, 4) == "@std" then
								return
							end

							print(
								text,
								string.split(Path.format(Path.basename(path)), ".")[1] == "init" and Path.dirname(path)
									or path
							)

							local module_absolute_path = Luau.resolveModule(
								text,
								string.split(Path.format(Path.basename(path)), ".")[1] == "init" and Path.dirname(path)
									or path
							)
							local module_cwd_relative_path =
								Path.format(Path.relative(Process.cwd(), module_absolute_path))

							if not modules[module_cwd_relative_path] then
								table.insert(paths, module_cwd_relative_path)
							end

							return `{CACHE_FUNCTION_NAME}("{module_cwd_relative_path}")`
						end)

					modules[path] = Printer.printFile(parse_result, replacements)
				end
			end
		end
	end

	for module_name, module in modules do
		writer:append("\n")
		writer:append_line(`{MODULES_NAME}["{module_name}"] = function()`)
		writer:indent()

		writer:append_lines(string.split(module, "\n"))
		writer:dedent()

		writer:append_line("end")
	end

	writer:append(`{CACHE_FUNCTION_NAME}("{entry_cwd_relative}")`)

	return writer:finalize()
end

return Bundler
