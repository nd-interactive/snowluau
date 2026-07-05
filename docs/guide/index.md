# Guide

## Installation

You can find and download the latest stable release on the 
[releases page](https://github.com/nd-interactive/snowluau/releases). They can also be installed with toolchain managers like [Rokit](https://github.com/rojo-rbx/rokit)
and [Foreman](https://github.com/Roblox/foreman).

### Install with Rokit

You can use [Rokit](https://github.com/rojo-rbx/rokit) to manage your Snowluau installation. If you have Rokit installed, simply run the following command in your project to install the latest stable version of Snowluau:

```bash
rokit add nd-interactive/snowluau@0.1.0
```

### Install with Foreman

You can also use [Foreman](https://github.com/Roblox/foreman) to manage your Snowluau installation. If you have Foreman installed, you must first create a `foreman.toml` file in your project with the following content:

```toml
[tools]
snowluau = { github = "nd-interactive/snowluau", version = "0.1.0" }
```

After creating the `foreman.toml` file, run the following command to install the latest stable version of Snowluau:
```bash
foreman install
```