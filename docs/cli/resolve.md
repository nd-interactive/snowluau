# resolve

Transforms string-based and `.luaurc`-based `require` calls into Roblox-compatible instance-based `require` calls.

## Usage

```bash
snowluau resolve <src> <out> [options]
```

## Options

### `-w, --watch`

## Examples

Outputs transformed mirror into `<out>`.
```bash
snowluau resolve src out
```

Outputs will transformed when `<src>` filesystem changes.
```bash
snowluau resolve src out
```