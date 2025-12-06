# topiary-nu

A Nix flake providing Topiary formatting functionality for Nushell with tree-sitter-nu grammar support.

## Description

This flake packages a custom build of Topiary language configuration and tree-sitter grammar specifically for Nushell (`.nu`) files. It enables proper syntax-aware formatting of Nushell scripts.

## Features

- Custom tree-sitter grammar for Nushell syntax
- Topiary language configuration for `.nu` files
- Built from [blindFS/topiary-nushell](https://github.com/blindFS/topiary-nushell)
- Includes compiled tree-sitter-nu parser
- ABI version 14 compatibility

## Usage

### Run directly
```bash
nix run github:ck3mp3r/flakes?dir=topiary-nu
```

### Install to profile
```bash
nix profile install github:ck3mp3r/flakes?dir=topiary-nu
```

### Use in flake.nix
```nix
{
  inputs = {
    topiary-nu.url = "github:ck3mp3r/flakes?dir=topiary-nu";
  };

  outputs = { self, nixpkgs, topiary-nu, ... }: {
    # Use topiary-nu.packages.${system}.default
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

## Components

This flake builds two main components:

1. **tree-sitter-nu**: Compiled tree-sitter grammar for Nushell
   - Generated from [nushell/tree-sitter-nu](https://github.com/nushell/tree-sitter-nu)
   - Compiled as shared library (`tree_sitter_nu.so`)
   - ABI version 14

2. **topiary-nu**: Language configuration for Topiary
   - Based on [blindFS/topiary-nushell](https://github.com/blindFS/topiary-nushell)
   - Includes language definitions and formatting rules
   - Configured for `.nu` file extensions

## Usage with Topiary

Once installed, you can use this with the main Topiary formatter:

```bash
# Format a Nushell file
topiary format --language nu script.nu

# Check formatting
topiary check --language nu script.nu
```

## Upstream Sources

- **Tree-sitter grammar**: [nushell/tree-sitter-nu](https://github.com/nushell/tree-sitter-nu)
- **Topiary configuration**: [blindFS/topiary-nushell](https://github.com/blindFS/topiary-nushell)
- **Topiary formatter**: [tweag/topiary](https://github.com/tweag/topiary)

## Building

This flake uses custom derivations to:
1. Compile the tree-sitter-nu grammar with proper ABI version
2. Package the language configuration files
3. Link the compiled grammar to the configuration
