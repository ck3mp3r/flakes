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
inputs.rustnix.url = "github:ck3mp3r/flakes?dir=rustnix&ref=main";
```

Then use the utilities from `lib` in your `flake.nix`:

```nix
archiveAndHash = rustnix.lib.archiveAndHash;
utils = rustnix.lib.utils;
rustBuild = rustnix.lib.rust.buildTargetOutputs;
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
  rustBuild.x86_64-linux # Native build for x86_64
  # or rustBuild.aarch64-linux # Cross-compiled build for ARM64
  # or rustBuild.default # Pre-built installer
```

### Cross-Compilation Usage

**✅ Correct way to cross-compile:**
```bash
# Build for ARM Linux (cross-compiles automatically if on different architecture)
nix build .#packages.aarch64-linux.my-package

# Build for x86 Linux
nix build .#packages.x86_64-linux.my-package

# Build for current system
nix build .#my-package
```

**❌ Don't use --system for cross-compilation:**
```bash
# This forces emulation/remote builders instead of cross-compilation
nix build --system aarch64-linux .#my-package  # AVOID THIS
```

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

Rustnix handles cross-compilation by:

1. **Build System**: Your actual machine (detected automatically) provides the toolchain
2. **Target Architectures**: Specified in the `supportedTargets` parameter, creates packages for each target
3. **Automatic Detection**: Cross-compilation happens when target ≠ build system
4. **Package Selection**: Use `.#packages.target-system.package` to build for specific targets

This approach provides:
- ✅ True cross-compilation (no emulation required)
- ✅ Uses native toolchain performance 
- ✅ Works in pure evaluation mode
- ✅ Compatible with CI/CD environments
- ✅ Follows standard Nix conventions

See the source in `lib/` for more information on available helpers and detailed options for Rust multiarch builds.
