# Flakes Collection

A collection of useful Nix flakes providing packaged software and tools.

## Available Flakes

| Flake | Description | Quick Usage |
|-------|-------------|-------------|
| [📦 base-nixpkgs](./base-nixpkgs/) | Pinned nixpkgs (unstable & stable 25.05) for consistent package versions | See usage below |
| [☸️ k8s-utils](./k8s-utils/) | Comprehensive Kubernetes CLI tools bundle | `nix shell github:ck3mp3r/flakes?dir=k8s-utils` |
| [💻 opencode](./opencode/) | AI coding agent with pre-populated cache and offline support | `nix run github:ck3mp3r/flakes?dir=opencode` |
| [🧰 rustnix](./rustnix/) | Reusable Nix library functions for Rust multiarch and artifact packaging | See [README](./rustnix/README.md) |
| [📊 slidev](./slidev/) | Presentation slides for developers | `nix run github:ck3mp3r/flakes?dir=slidev` |
| [🌳 topiary-nu](./topiary-nu/) | Nushell formatting with tree-sitter | `nix run github:ck3mp3r/flakes?dir=topiary-nu` |

## Quick Start

### Run any flake directly
```bash
nix run github:ck3mp3r/flakes?dir=<flake-name>
```

### Install to your profile
```bash
nix profile install github:ck3mp3r/flakes?dir=<flake-name>
```

### Use in your flake.nix
```nix
{
  inputs = {
    <flake-name>.url = "github:ck3mp3r/flakes?dir=<flake-name>";
  };
}
```

Replace `<flake-name>` with `base-nixpkgs`, `k8s-utils`, `topiary-nu`, `rustnix`, `slidev`, or `opencode`.

## Using base-nixpkgs

The `base-nixpkgs` flake pins versions of nixpkgs-unstable and stable (NixOS 25.05) that can be shared across multiple projects via the `follows` pattern. This is useful for:

- **Single source of truth**: One flake.lock to manage nixpkgs version
- **Reduced duplication**: Multiple flakes share the same nixpkgs store paths
- **Easy updates**: `nix flake update` in one place updates everywhere
- **Consistency**: All projects use identical package versions

### Using `follows` to Share nixpkgs

Use `follows` to make all your flake inputs share the same pinned nixpkgs versions:

```nix
{
  inputs = {
    base-nixpkgs.url = "github:ck3mp3r/flakes?dir=base-nixpkgs";

    # Make other flakes use the same unstable nixpkgs
    some-other-flake.url = "github:someone/flake";
    some-other-flake.inputs.nixpkgs.follows = "base-nixpkgs/unstable";

    # Works with any flake that has nixpkgs as an input
    rustnix.url = "github:ck3mp3r/flakes?dir=rustnix";
    rustnix.inputs.nixpkgs.follows = "base-nixpkgs/unstable";
  };

  outputs = inputs @ {flake-parts, base-nixpkgs, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      perSystem = {pkgs, ...}: {
        # All flakes now use the exact same nixpkgs version
        packages.default = pkgs.hello;
      };
    };
}
```

To use stable (25.05) instead, use `base-nixpkgs/stable` in the follows pattern.

This pattern ensures:
- No duplicate nixpkgs in your flake.lock
- All dependencies use compatible package versions
- Smaller closure sizes due to shared dependencies

## Contributing

Feel free to submit PRs for additional useful flakes or improvements to existing ones. Each flake should:

- Be self-contained in its own directory
- Include comprehensive documentation in its README
- Follow Nix best practices
- Include proper licensing information

## License

This repository is licensed under the Apache License 2.0. Individual packages may have their own licenses - see their respective documentation for details.
