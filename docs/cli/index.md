---
order: 2
---

# CLI Reference

네

## Usage

```bash
snowluau <command> [options] [arguments...]
```

## Commands

| Command | Description |
| ------- | ----------- |
| [resolve](./resolve) | Transforms string-based and `.luaurc`-based `require` calls into Roblox-compatible instance-based `require` calls. |
| [bundle](./bundle) | Bundles a multi-file module into a single file by following its require graph. |
| [rename](./rename) | Renames all local variables to a sequence of generated variable names. |

## Global Options

| Option | Description |
| ------ | ----------- |
| `-h`, `--help` | Display help message for the command. |