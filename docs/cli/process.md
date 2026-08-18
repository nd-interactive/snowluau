---
order: 1
---

# process

Generates output with the transformer rules defined in snowluau.toml applied.

## Usage

```bash
snowluau process [options] <src> <out>
```

## Options

### `-w, --watch`

## Examples

Outputs transformed mirror into `<out>`.
```bash
snowluau process src out
```

Outputs will transformed when `<src>` filesystem changes.
```bash
snowluau process --watch src out
```