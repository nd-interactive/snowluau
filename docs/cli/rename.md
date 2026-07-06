---
order: 3
---

# rename

Renames all local variables to a sequence of generated variable names.


## Usage

```bash
snowluau rename <src> <out> [options]
```

## Options

No.

## Examples

In the output, the names of local variables, parameters, and other variables from the original script will be transformed into a sequence of generated variable names.
```bash
snowluau rename src out
```

For example:
```lua
local fiz, wiz = true, false
local function hello(world)
    fiz, wiz = wiz, fiz
end
```
becomes
```lua
local v_0001, v_0002 = false, true
local function v_0003(v_0004)
    v_0001, v_0002 = v_0002, v_0001
end
```