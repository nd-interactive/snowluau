
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

### `index_style`

Controls how Roblox instances are referenced in the transformed `require` call.

- Type: `string`
- Default: `"string"`

| Value | Generated style |
| --- | --- |
| `"string"` | `require("@game/ReplicatedStorage/packages/hello")` |
| `"find_first_child"` | `require(game:GetService("ReplicatedStorage"):FindFirstChild("packages"):FindFirstChild("hello"))` |
| `"wait_for_child"` | `require(game:GetService("ReplicatedStorage"):WaitForChild("packages"):WaitForChild("hello"))` |

```toml
[[process]]
name = "resolve_roblox_requires"
options = { index_style = "wait_for_child" }
```
