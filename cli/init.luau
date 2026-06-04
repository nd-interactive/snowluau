local Fs = require("@std/fs")
local Json = require("@std/json")
local Path = require("@std/path")
local Task = require("@std/task")

local CLIBuilder = require("./luau_packages/cli_builder")

local Resolver = require("./src/resolver")
local Bundler = require("./src/bundler")

local SOURCEMAP_PATH = "sourcemap.json"

local NAME = "snowluau"
local VERSION = "0.1.0"

export type Sourcemap = {
	name: string,
	className: string,
	filePaths: { string }?,
	children: { Sourcemap }?,
}

local function process_paths()
	local sourcemap = Json.deserialize(Fs.readFileToString(SOURCEMAP_PATH)) :: Sourcemap

	local instance_paths = {}

	local nodes = table.clone(assert(sourcemap.children, "Datamodel includes no children"))
	local file_paths = {}

	for _, service in nodes do
		instance_paths[service] = `game:GetService("{service.name}")`
	end

	while next(nodes) do
		local node = table.remove(nodes) :: Sourcemap

		local children = node.children

		if children then
			for _, child in children do
				local name = child.name
				local paths = child.filePaths

				local instance_path = `{instance_paths[node]}:WaitForChild("{name}")`

				instance_paths[child] = instance_path

				if paths then
					for _, path in paths do
						file_paths[path] = instance_path
					end
				end

				table.insert(nodes, child)
			end
		end
	end

	return file_paths
end

local function process(src: string, out: string)
	local instance_paths = process_paths()
	local start = os.clock()

	local walker = Fs.walk(out, {
		recursive = true,
	})

	local path = walker()
	while path do
		local path_type = Fs.type(path)
		local path_ext = Path.extname(path)

		if path_type == "dir" then
			Fs.createDirectory(path, {
				makeParents = true,
			})
		elseif path_type == "file" then
			local success, message = xpcall(function(...)
				local destination = Path.join(out, Path.relative(src, path))

				if path_ext == ".lua" or path_ext == ".luau" then
					Fs.writeStringToFile(destination, Resolver.resolve(path, instance_paths))
				else
					Fs.copy(src, destination)
				end
			end, debug.traceback)

			if not success then
				print(`failed to resolve "{path}"\n\n{message}`)
			end
		end

		path = walker()
	end

	print("processing took " .. tostring(os.clock() - start) .. "s")
end

local function process_clear(src: string, out: string)
	local walker = Fs.walk(out, {
		recursive = true,
	})

	local path = walker()
	while path do
		if Fs.exists(path) and not Fs.exists(Path.join(src, Path.relative(out, path))) then
			local path_type = Fs.type(path)

			if path_type == "dir" then
				Fs.removeDirectory(path, {
					recursive = true,
				})
			elseif path_type == "file" then
				Fs.remove(path)
			end
		end

		path = walker()
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
		:setName("resolve")
		:setDescription("Transfrom string-based require to roblox instance-based require")
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

			process_clear(input, output)
			process(input, output)

			if optionArguments.watch then
			end
		end)
		:build())
	:addCommand(CLIBuilder.command
		.new()
		:setName("bundle")
		:setDescription("bundle a bunch of scripts into single script")
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
			--local optionArguments = options.commandOptions

			local input = commandArguments.input
			local output = commandArguments.output

			Fs.writeStringToFile(output, Bundler.bundle(input))
		end)
		:build())
	:run({ select(2, ...) })
