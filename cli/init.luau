local Fs = require("@std/fs")
local Json = require("@std/json")
local Path = require("@std/path")

local Transformer = require("./src/transformer")

local LUAURC_PATH = ".luaurc"
local SOURCEMAP_PATH = "sourcemap.json"

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
			Fs.writeStringToFile(out_path, Transformer.transform(Fs.readFileToString(src_path), aliases, paths))
		end
	end
end

process("src", "out")
