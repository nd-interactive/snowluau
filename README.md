# Snowluau
A lute-based transformer/bundler


```bash
snowluau help
```

# Build
```bash
rokit install
pesde install
lute compile cli/init.luau --output snowluau
```

# Install
```bash
rokit add nd-interactive/snowluau@version
rokit install
```

# Example
`snowluau.toml`
```toml
[[process]]
name = "resolve_roblox_requires",
```

snowluau process --watch src out