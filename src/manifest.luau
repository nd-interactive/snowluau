local Fs = require("@std/fs")
local Path = require("@std/path")
local Toml = require("@libs/toml")

local Manifest = {}

local MANIFEST_NAME = "snowluau.toml"

export type Process = string
export type Manifest = {
    processes: { Process }
}

function Manifest.readManifest(): Manifest
	return Toml.deserialize(Fs.readFileToString(Path.parse(MANIFEST_NAME))) :: Manifest
end

return Manifest