
# Resolve Roblox Requires
The luau-style requires will transformed into roblox roblox-require-style.

## Example
```luau
local Hello = require("@pkgs/hello")
```
into
```luau
local Hello = require("@game/ReplicatedStorage/packages/hello")
```

## Options