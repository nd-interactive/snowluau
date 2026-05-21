local Fs = require("@std/fs")
local Json = require("@std/json")
local Path = require("@std/path")
local Task = require("@std/task")

local CLIBuilder = require("./luau_packages/cli_builder")

local Transformer = require("./src/transformer")

local LUAURC_PATH = ".luaurc"
local SOURCEMAP_PATH = "sourcemap.json"

local NAME = "snowluau"
local VERSION = "0.1.0"

local function process_aliases()
	local luaurc = Json.deserialize(Fs.readFileToString(LUAURC_PATH))

	return luaurc.aliases
end

local function process_paths()
	local sourcemap = Json.deserialize(Fs.readFileToString(SOURCEMAP_PATH))

	local instance_paths = {}

	local nodes = table.clone(sourcemap.children)
	local file_paths = {}

	for _, service in nodes do
		instance_paths[service] = `game:GetService("{service.name}")`
	end

	while next(nodes) do
		local node = table.remove(nodes)

		local children = node.children

		if children then
			for _, child in children do
				local name = child.name
				local paths = child.filePaths

				local instance_path = `{instance_paths[node]}:WaitForChild("{name}")`

				instance_paths[child] = instance_path

				if paths then
					for _, path in paths do
						local base_name = Path.basename(path)
						local dir_name = Path.dirname(path)
						local ext_name = Path.extname(path)
						local stem_name = string.sub(base_name, 1, #base_name - #ext_name)

						local require_path = (base_name == "init.luau" or base_name == "init.lua") and dir_name
							or `{dir_name}/{stem_name}`

						file_paths[require_path] = instance_path
					end
				end

				table.insert(nodes, child)
			end
		end
	end

	return file_paths
end

local function process(src: string, out: string)
	local aliases = process_aliases()
	local paths = process_paths()

	local src_paths: { Path.Path } = { src }
	local out_paths: { [Path.Path]: Path.Path } = { [src] = out }

	local start = os.clock()

	while next(src_paths) do
		local src_path = table.remove(src_paths)
		local src_type = Fs.type(src_path)
		local out_path = out_paths[src_path]

		if src_type == "dir" then
			if not Fs.exists(out_path) then
				Fs.createDirectory(out_path)
			end

			for _, child in Fs.listDirectory(src_path) do
				local child_path = Path.join(src_path, child.name)
				local child_out_path = Path.join(out_path, child.name)

				table.insert(src_paths, child_path)
				out_paths[child_path] = child_out_path
			end
		elseif src_type == "file" then
			local src_ext = Path.extname(src_path)
			local src_content = Fs.readFileToString(src_path)

			xpcall(function()
				if src_ext == ".luau" or src_ext == ".lua" then
					Fs.writeStringToFile(out_path, Transformer.transform(src_content, aliases, paths))
				else
					Fs.writeStringToFile(out_path, src_content)
				end
			end, function()
				print(`failed to transform "{src_path}"`)
			end)
		end
	end

	print("processing took " .. tostring(os.clock() - start) .. "s")
end

local function process_clear(src: string, out: string)
	local out_paths: { Path.Path } = { out }
	local src_paths: { [Path.Path]: Path.Path } = { [out] = src }

	while next(out_paths) do
		local out_path = table.remove(out_paths)
		local out_type = Fs.type(out_path)
		local src_path = src_paths[out_path]

		if not Fs.exists(src_path) then
			if out_type == "dir" then
				Fs.removeDirectory(out_path, { recursive = true })
			else
				Fs.remove(out_path)
			end
		else
			if out_type == "dir" then
				for _, child in Fs.listDirectory(out_path) do
					local child_path = Path.join(out_path, child.name)
					local child_src_path = Path.join(src_path, child.name)

					table.insert(out_paths, child_path)
					src_paths[child_path] = child_src_path
				end
			end
		end
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
		:setName("transform")
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
	:run({ select(2, ...) })
