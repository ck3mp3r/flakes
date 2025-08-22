# Slidev Nix Flake

This Nix flake packages [Slidev](https://sli.dev), a presentation slides tool for developers.

## Usage

### Install Slidev globally

```bash
# Install with nix profile
nix profile install github:ck3mp3r/flakes?dir=slidev#slidev

# Or run directly
nix run github:ck3mp3r/flakes?dir=slidev#slidev -- --help
```

### Use in a development environment

```bash
# Enter a development shell with Slidev available
nix develop github:ck3mp3r/flakes?dir=slidev#slidev
```

### Add to your system flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    slidev-flake.url = "github:ck3mp3r/flakes?dir=slidev";
  };

  outputs = { self, nixpkgs, slidev-flake }: {
    # Your configuration here
    environment.systemPackages = [
      slidev-flake.packages.${system}.slidev
    ];
  };
}
```

## Building locally

```bash
# Navigate to the slidev directory
cd slidev

# Build the package
nix build .#slidev

# Run the built package  
./result/bin/slidev --help

# Format the flake (uses Alejandra)
nix fmt .
```

## Features

- Uses GitHub source as flake input for reproducibility
- Includes proper Node.js 20 runtime
- Provides both CLI application and development shell
- Follows Nix flake best practices

## Requirements

- Nix with flakes enabled
- Node.js >=18.0.0 (provided by the flake)

## Updating

To update to the latest Slidev version:

```bash
nix flake update
```

This will update the `slidev-src` input to the latest commit from the Slidev repository.

## Implementation

This flake uses a pragmatic approach:

1. **Source Input**: Uses the official Slidev GitHub repository as a flake input for version tracking
2. **Runtime Approach**: Creates a wrapper that uses `npx @slidev/cli@latest` to ensure you always get the latest compatible version
3. **No Complex Build**: Avoids the complexity of building the entire pnpm monorepo by delegating to npm's package manager

## Testing

To verify the installation works:

```bash
# Navigate to the slidev directory first
cd slidev

# Test version
nix run .#slidev -- --version

# Test help
nix run .#slidev -- --help

# Create a simple presentation
mkdir test-presentation
cd test-presentation
echo "# Hello Slidev" > slides.md
nix run ..#slidev
```

### Testing from outside the directory

```bash
# Test from anywhere using the full GitHub path
nix run github:ck3mp3r/flakes?dir=slidev#slidev -- --version
```