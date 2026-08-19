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

return Sourcemap
