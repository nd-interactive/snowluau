local Luau = require("@std/luau")
local Fs = require("@std/fs")
local Path = require("@std/path")

local Writer = require("./writer")

local Bundler = {}

local MODULES_NAME = "__SNOWLUAU_MODULES"
local CACHES_NAME = "__SNOWLUAU_CACHES"
local CACHE_FUNCTION_NAME = "__SNOWLUAU_CACHE_FUNCTION"

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

	writer:dedent()
	writer:append_line("end")
	writer:append("\n")

	return writer:finalize()
end

local result = Bundler.bundle("entry")
print(result)

return Bundler
