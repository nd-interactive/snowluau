local CLIBuilder = require("@pkgs/cli_builder")

local Path = require("@std/path")
local Fs = require("@std/fs")
local Process = require("@std/process")
local TableExt = require("@std/tableext")

local Watch = require("@libs/watch")
local Transformers = require("@src/transformers")
local Manifest = require("@src/manifest")

local NAME = "snowluau"
local VERSION = "0.1.0"

local function transform(input: Path.Path, output: Path.Path)
	local manifest: Manifest.Manifest = Manifest.readManifest()

	local replacements = {}
	for _, process: Manifest.Process in manifest.process do
		
		local transformer = Transformers["resolve_roblox_require"]

		TableExt.combine(replacements )
	end
end

CLIBuilder.cli
	.new()
	:setName(NAME)
	:setVersion(VERSION)
	:setDescription("Luau transformer/bundler")
	:setGitRepository("https://github.com/nd-interactive/snowluau")
	:addCommand(CLIBuilder.command
		.new()
		:setName("process")
		:setDescription("Process transforms.")
		:addOption(
			CLIBuilder.option
				.new()
				:setName("watch")
				:addAlias("w")
				:setDescription("Watch changes")
				:setType("boolean")
				:setDefaultValue(false)
				:build()
		)
		:addArgument(
			CLIBuilder.argument
				.new()
				:setName("input")
				:setDescription("Path to input")
				:setType("string")
				:setRequired(true)
				:build()
		)
		:addArgument(
			CLIBuilder.argument
				.new()
				:setName("output")
				:setDescription("Path to output")
				:setType("string")
				:setRequired(true)
				:build()
		)
		:setCallback(function(options)
			local commandArguments = options.commandArguments
			local optionArguments = options.commandOptions

			local input = commandArguments.input
			local output = commandArguments.output

			local cwd = Process.cwd()

			local input_path = Path.relative(cwd, input)
			local output_path = Path.relative(cwd, output)

			transform(input_path, output_path)
			if optionArguments.watch then
				Watch.watch(input_path, function(_, _)
					transform(input_path, output_path)
				end)
			end
		end)
		:build())
	:run({ select(2, ...) })
