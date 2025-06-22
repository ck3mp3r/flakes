# mods

A Nix flake for the [charmbracelet/mods](https://github.com/charmbracelet/mods) CLI tool - AI on the command line.

## Description

This flake packages the mods CLI tool, which allows you to interact with AI models directly from your terminal. It supports various AI providers and can be used for code generation, text processing, and general AI assistance.

## Features

- Built from the latest upstream source
- Go module with proper dependency management
- Includes version information in binary
- Apache 2.0 licensed (this flake)
- Cross-platform support (Linux, macOS, Windows)

## Usage

### Run directly
```bash
nix run github:ck3mp3r/flakes?dir=mods
```

### Install to profile
```bash
nix profile install github:ck3mp3r/flakes?dir=mods
```

### Use in flake.nix
```nix
{
  inputs = {
    mods.url = "github:ck3mp3r/flakes?dir=mods";
  };
  
  outputs = { self, nixpkgs, mods, ... }: {
    # Use mods.packages.${system}.default
  };
}
```

### Local development
```bash
# From this directory
nix run .

# Build locally
nix build .
```

## Configuration

After installation, you'll need to configure mods with your AI provider API keys. See the [upstream documentation](https://github.com/charmbracelet/mods#configuration) for details.

## Upstream

- **Source**: [charmbracelet/mods](https://github.com/charmbracelet/mods)
- **License**: MIT
- **Version**: Built from latest commit (unstable)

## Building

This flake uses `buildGoModule` with:
- `vendorHash = null` and `proxyVendor = true` for dependency management
- Version information embedded via ldflags
- Automatic dependency resolution from go.mod/go.sum
