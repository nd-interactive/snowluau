local Fs = require("@std/fs")
local Json = require("@std/json")
local Path = require("@std/path")

local Sourcemap = {}

local SOURCEMAP_NAME = "sourcemap.json"

export type Sourcemap = {
	name: string,
	className: string,
	filePaths: { string }?,
	children: { Sourcemap }?,
}

function Sourcemap.readSourcemap(): Sourcemap
	return Json.deserialize(Fs.readFileToString(Path.parse(SOURCEMAP_NAME))) :: Sourcemap
end

function Sourcemap.getFilePathMap(sourcemap: Sourcemap)
	local node_paths = {} :: { [Sourcemap]: string }
	local instance_paths_mapped = {} :: { [string]: string }

	local nodes = assert(table.clone(sourcemap.children))

	for _, service in nodes do
		node_paths[service] = `@game/{service.name}`
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

			local instance_path = `{node_paths[current]}/{name}`
			node_paths[child] = instance_path

			if paths then
				for _, path in paths do
					instance_paths_mapped[path] = instance_path
				end
			end

			table.insert(nodes, child)
		end
	end

	return instance_paths_mapped
end

return Sourcemap