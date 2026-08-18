local Fs = require("@std/fs")
local Path = require("@std/path")
local Toml = require("@libs/toml")

local Manifest = {}

local MANIFEST_NAME = "snowluau.toml"

export type Process = {
	name: keyof<typeof(require("./transformers"))>,
	options: { [string]: string | boolean },
}
export type Manifest = { -- TODO: options를 포함해야 할것 같음.
	process: { Process },
}

function Manifest.readManifest(): Manifest
	return Toml.deserialize(Fs.readFileToString(Path.parse(MANIFEST_NAME))) :: Manifest
end

return Manifest
