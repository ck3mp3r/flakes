# rustnix

Reusable Nix library functions for multi-architecture Rust builds, artifact archiving/hashing, and platform/architecture helpers.

## Provided Utilities

- **rust.buildPackages**: Flexible multi-architecture Rust build helper. Allows you to build Rust projects for multiple Nix systems (native and cross), optionally archive/hash outputs with `archiveAndHash`, and integrate custom overlays and toolchains. See below for full usage and parameters.
- **archiveAndHash**: Archive a build output into a `.tgz` and generate both a Nix-style hash and a standard SHA256 hash, all with user-friendly names. Useful for distributing and verifying build artifacts.
- **utils**: Helper functions for system/platform mapping:
  - `systemMap`: Extracts architecture and platform from a Nix system string.
  - `getTarget`: Maps a Nix system string to a typical Rust/gnu-style target triple.

## Usage

Add this flake as an input to your own flake:

```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  rustnix.url = "github:ck3mp3r/flakes?dir=rustnix&ref=main";
  fenix = {
    url = "github:nix-community/fenix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  devenv = {
    url = "github:cachix/devenv";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Make rustnix follow your input versions
  rustnix.inputs.nixpkgs.follows = "nixpkgs";
  rustnix.inputs.fenix.follows = "fenix";
  rustnix.inputs.devenv.follows = "devenv";
};
```

Then use the utilities from `lib` in your `flake.nix`:

```nix
archiveAndHash = rustnix.lib.archiveAndHash;
utils = rustnix.lib.utils;
rustBuild = rustnix.lib.rust.buildTargetOutputs;
```

### Development Environment

This flake includes a devenv shell with Rust toolchain from fenix. Enter the development environment:

```bash
nix develop --no-pure-eval
```

The dev shell includes:
- Rust stable toolchain (via fenix)
- Alejandra formatter
- Pre-commit hooks with alejandra

**Note:** Due to devenv integration, this flake requires `--no-pure-eval` for commands like `nix flake check`. In CI/CD workflows, use:
```bash
nix flake check --no-pure-eval
```

### Example: Multi-Architecture Rust Build

```nix
let
  rustBuild = rustnix.lib.rust.buildTargetOutputs {
    pkgs = pkgs;
    nixpkgs = nixpkgs;
    overlays = []; # Optionally add overlays
    fenix = fenix;
    system = "x86_64-linux";  # Build system (your machine)
    supportedTargets = [ "x86_64-linux" "aarch64-linux" ];  # Supported target architectures
    cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
    cargoLock = { lockFile = ./Cargo.lock; };
    src = ./.;
    installData = {}; # Optional, see source for details
    archiveAndHash = true; # Set to false to disable artifact archiving
    extraArgs = {}; # Optional, extra args for build
  };
in
  rustBuild # Returns { default = derivation; packageName = derivation; ... }
```

### Usage with flake-parts

The typical usage pattern with `flake-parts`:

```nix
outputs = inputs @ { flake-parts, nixpkgs, rustnix, fenix, ... }:
  flake-parts.lib.mkFlake { inherit inputs; } {
    systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

    perSystem = { pkgs, system, ... }: {
      packages = rustnix.lib.rust.buildTargetOutputs {
        inherit system pkgs;
        nixpkgs = nixpkgs;
        fenix = fenix;
        supportedTargets = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
        cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
        cargoLock = { lockFile = ./Cargo.lock; };
        src = ./.;
        overlays = [];
        archiveAndHash = false;
      };
    };
  };
```

This creates:
```
packages.x86_64-linux.default
packages.aarch64-linux.default
packages.aarch64-darwin.default
```

### Overriding Inputs

You can override nixpkgs, fenix, or devenv when consuming this flake:

```nix
inputs = {
  rustnix.url = "github:ck3mp3r/flakes?dir=rustnix";
  nixpkgs.url = "github:nixos/nixpkgs/specific-branch";
  fenix.url = "github:nix-community/fenix/specific-commit";
  devenv.url = "github:cachix/devenv/specific-version";

  # Make rustnix follow your inputs
  rustnix.inputs.nixpkgs.follows = "nixpkgs";
  rustnix.inputs.fenix.follows = "fenix";
  rustnix.inputs.devenv.follows = "devenv";
};
```

This allows you to:
- Pin specific versions of dependencies across your project
- Use custom nixpkgs branches or commits
- Control Rust toolchain versions via fenix
- Manage devenv versions for development environments


### Example: Archiving and Hashing a Build Output

```nix
outputs = { self, rustnix, nixpkgs, ... }: {
  packages.x86_64-linux.example = let
    pkgs = import nixpkgs { system = "x86_64-linux"; };
    myDrv = pkgs.stdenv.mkDerivation {
      name = "my-artifact";
      src = ./.;
      buildPhase = ":";
      installPhase = ''
        mkdir -p $out
        echo "Hello, world!" > $out/hello.txt
      '';
    };
    archive = rustnix.lib.archiveAndHash {
      pkgs = pkgs;
      drv = myDrv;
      name = "my-artifact";
    };
  in archive;
};
```

### Example: Using Platform Helpers

```nix
let
  systemInfo = rustnix.lib.utils.systemMap "x86_64-linux";
  targetTriple = rustnix.lib.utils.getTarget "x86_64-linux";
in
  # systemInfo = { arch = "x86_64"; platform = "linux"; }
  # targetTriple = "x86_64-unknown-linux-musl"
```

## Cross-Compilation Approach

Cross-compilation happens automatically when the target differs from your build machine.

See the source in `lib/` for more information on available helpers and detailed options for Rust multiarch builds.
