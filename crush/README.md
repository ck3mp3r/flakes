# crush

A Nix flake for the [charmbracelet/crush](https://github.com/charmbracelet/crush) TUI app — AI on the command line.

## Description

This flake packages the `crush` TUI (terminal user interface) application, enabling seamless usage of the glamourous AI coding agent directly from your terminal.

## Features

- Built from the latest upstream source
- Go module with proper dependency management
- Includes version information in the binary
- MIT licensed (this flake)
- Cross-platform support (Linux, macOS, Windows)

## Usage

### Run directly
```bash
nix run github:ck3mp3r/flakes?dir=crush
```

### Install to profile
```bash
nix profile install github:ck3mp3r/flakes?dir=crush
```

### Use in flake.nix
```nix
{
  inputs = {
    crush.url = "github:ck3mp3r/flakes?dir=crush";
  };
  
  outputs = { self, nixpkgs, crush, ... }: {
    # Use crush.packages.${system}.default
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

After installation, configure crush for your AI provider if required. See the [upstream documentation](https://github.com/charmbracelet/crush) for details.

## Upstream

- **Source**: [charmbracelet/crush](https://github.com/charmbracelet/crush)
- **License**: MIT
- **Version**: Built from latest commit (unstable)

## Building

This flake uses `buildGoModule` with:
- `vendorHash = null` and `proxyVendor = true` for dependency management
- Version information embedded via ldflags
- Automatic dependency resolution from go.mod/go.sum

