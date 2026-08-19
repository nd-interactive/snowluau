local CLIBuilder = require("@pkgs/cli_builder")

local Path = require("@std/path")
local Fs = require("@std/fs")
local Printer = require("@std/syntax/printer")
local Syntax = require("@std/syntax")
local Transform = require("@transform")

local Watch = require("@libs/watch")
local Transformers = require("@src/transformers")
local Manifest = require("@src/manifest")

local NAME = "snowluau"
local VERSION = "0.1.0"

local function transform(input: Path.Path, output: Path.Path)
	local manifest: Manifest.Manifest = Manifest.readManifest()

	local walker = Fs.walk(input, { recursive = true })
	local path = walker()

	local start = os.clock()

	while path do
		local type = Fs.type(path)
		local ext = Path.extname(path)
		local output_path = Path.join(output, Path.relative(input, path))

		if type == "dir" then
			Fs.createDirectory(output_path, { makeParents = true })
		elseif type == "file" and (ext == ".lua" or ext == ".luau") then
			local source = Fs.readFileToString(path)

			for _, process: Manifest.Process in manifest.process do
				-- TODO: really idk how to resolve this type error.
				local transformer = Transformers[process.name] :: Transform.Migration
				local options: { [unknown]: unknown } = {}

				if transformer.options then
					for _, config_option in transformer.options do
						options[config_option.name] = process.options and process.options[config_option.name]
							or config_option.default
					end
				end

				-- TODO: xpcall is confusing type solves.
				local success, message = xpcall(
					function()
						if transformer.initialize then
							transformer.initialize({
								options = options,
							})
						end

						local parseresult = Syntax.parse(source)
						local replacements = transformer.transform({
							path = Path.format(path :: any), -- this too. inline(?) function confusing this. idk.
							source = source,
							parseresult = parseresult,
							options = options,
						})
						if typeof(replacements) == "string" then
							source = replacements
						else
							source = Printer.printFile(parseresult, replacements)
						end
					end :: any,
					debug.traceback :: any
				)

				if not success then
					print(`Failed to transform "{Path.format(path)}" to "{process.name}":\n\n{message}`)
				end
			end

			Fs.writeStringToFile(output_path, source)
		else
			Fs.copy(path, output_path)
		end

		path = walker()
	end

	print("processing took " .. tostring(os.clock() - start) .. "s")
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

			local input_path = Path.resolve(input)
			local output_path = Path.resolve(output)

			if Fs.exists(output_path) then
				if Fs.type(output_path) == "dir" then
					Fs.removeDirectory(output_path, {
						recursive = true,
					})
				else
					Fs.remove(output_path)
				end
			end

			transform(input_path, output_path)
			if optionArguments.watch then
				Watch.watch(input_path, function(path: Path.Path, change: Watch.Change)
					if change.changed or change.created then
						transform(input_path, output_path)
					elseif change.removed then
						local path_to_remove = Path.join(output_path, Path.relative(input_path, path))
						if Fs.exists(path_to_remove) then
							if Fs.type(path_to_remove) == "dir" then
								Fs.removeDirectory(path_to_remove, {
									recursive = true,
								})
							else
								Fs.remove(path_to_remove)
							end
						end
					end
				end)
			end
		end)
		:build())
	:run({ select(2, ...) })
