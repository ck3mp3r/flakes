# rustnix

Reusable Nix library functions for multi-architecture Rust builds with internalized fenix toolchain management, artifact archiving/hashing, and platform/architecture helpers.

## Provided Utilities

### Rust Build Functions

- **`buildTargetOutputs`**: Multi-architecture Rust build helper. Builds Rust projects for the current system (when it's in `supportedTargets`), handles cross-compilation automatically, and optionally archives/hashes outputs.
- **`mkPkgs`**: Import nixpkgs with standard configuration (allowUnfree, optional crossSystem support).
- **`mkToolchain`**: Create a Rust toolchain with fenix, supporting additional targets and extra components (rustfmt, clippy, rust-analyzer).
- **`mkRustPlatform`**: Convenience function combining `mkPkgs` and `mkToolchain` to create a configured Rust platform.
- **`overlays.fenix`**: Fenix overlay for consumers who need direct access to fenix packages.
- **mkCrossPkgs**: Configure cross-compilation pkgs and toolchain for a specific target. Returns { callPackage, pkgs, toolchain }.
- **mkPackageSet**: Assemble package attribute sets from components (default, named, aliases).
### Helper Functions

- **`archiveAndHash`**: Archive a build output into a `.tgz` and generate both a Nix-style hash and a standard SHA256 hash, all with user-friendly names. Useful for distributing and verifying build artifacts.
- **`utils`**: Helper functions for system/platform mapping:
  - `systemMap`: Extracts architecture and platform from a Nix system string.
  - `getTarget`: Maps a Nix system string to a Rust target triple (defaults to musl variant).

## Usage

### Flake Inputs

Add this flake as an input to your own flake. **Note:** fenix is now internalized, so you only need `nixpkgs` and `rustnix`:

```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  rustnix.url = "github:ck3mp3r/flakes?dir=rustnix&ref=main";

  # Make rustnix follow your nixpkgs version
  rustnix.inputs.nixpkgs.follows = "nixpkgs";
};
```

### Importing the Library

Use the utilities from `lib` in your `flake.nix`:

```nix
# Individual imports
archiveAndHash = rustnix.lib.archiveAndHash;
utils = rustnix.lib.utils;
rustBuild = rustnix.lib.rust.buildTargetOutputs;
# Or access the entire rust lib
rust = rustnix.lib.rust;
```

## Core Functions

### `buildTargetOutputs`

Builds a Rust package for the current system (when supported). Returns packages for the current system only, not all targets.

**Parameters:**
```nix
{
  # Required
  system               # Build system (e.g., "x86_64-linux")
  supportedTargets     # List of supported systems (e.g., ["x86_64-linux" "aarch64-linux"])
  nixpkgs              # nixpkgs flake input
  pkgs                 # pkgs instance for the build system
  src                  # Source directory
  cargoToml            # Parsed Cargo.toml (use builtins.fromTOML)
  cargoLock            # Cargo.lock reference { lockFile = ./Cargo.lock; }

  # Optional
  overlays             # List of nixpkgs overlays (default: [])
  archiveAndHash       # Create .tgz archive (default: false)
  packageName          # Custom package name (default: null, uses cargoToml.package.name)
  aliases              # List of package aliases (default: [])
  linuxVariant         # "musl" or "gnu" (default: "musl")
  buildInputs          # Additional build dependencies (default: [])
  nativeBuildInputs    # Additional native build dependencies (default: [])
  extraArgs            # Additional args passed to build (default: {})
  installData          # Pre-built installer data by system (default: null)
  additionalTargets    # Extra Rust targets (e.g., ["wasm32-unknown-unknown"]) (default: [])
}
```

**Returns:**
- Empty set `{}` if current system is not in `supportedTargets`
- Otherwise: `{ default = derivation; packageName = derivation; ...aliases... }`

**Example:**
```nix
let
  rustBuild = rustnix.lib.rust.buildTargetOutputs {
    inherit system pkgs;
    nixpkgs = nixpkgs;
    supportedTargets = [ "x86_64-linux" "aarch64-linux" ];
    cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
    cargoLock = { lockFile = ./Cargo.lock; };
    src = ./.;
    overlays = [];
    archiveAndHash = false;
  };
in
  rustBuild  # { default = derivation; }
```

### `mkPkgs`

Import nixpkgs with standard configuration. Sets allowUnfree by default and supports optional crossSystem for cross-compilation.

**Parameters:**
```nix
{
  system      # Target system (e.g., "x86_64-linux")
  nixpkgs     # nixpkgs flake input
  overlays    # List of overlays to apply (default: [])
  config      # Custom nixpkgs config (default: {}, merged with {allowUnfree = true;})
  crossSystem # Optional cross-compilation system config (default: null)
}
```

**Example:**
```nix
pkgs = rustnix.lib.rust.mkPkgs {
  system = "x86_64-linux";
  nixpkgs = inputs.nixpkgs;
  overlays = [ myOverlay ];
};
```

### `mkToolchain`

Create a Rust toolchain from fenix with additional targets and components.

**Parameters:**
```nix
{
  system    # Build system (e.g., "x86_64-linux")
  targets   # Additional target triples to include (default: [])
  extras    # Extra components: "rustfmt", "clippy", "rust-analyzer" (default: [])
  variant   # Linux variant: "musl" or "gnu" (default: "musl")
}
```

**Example:**
```nix
# Basic toolchain
toolchain = rustnix.lib.rust.mkToolchain {
  system = "x86_64-linux";
};

# Toolchain with cross-compilation and dev tools
toolchain = rustnix.lib.rust.mkToolchain {
  system = "x86_64-linux";
  targets = [ "aarch64-unknown-linux-musl" "x86_64-unknown-linux-gnu" ];
  extras = [ "rustfmt" "clippy" "rust-analyzer" ];
};
```

### `mkRustPlatform`

Convenience function combining `mkPkgs` and `mkToolchain` to create a configured Rust build platform.

**Parameters:**
```nix
{
  system      # Build system
  nixpkgs     # nixpkgs flake input
  overlays    # nixpkgs overlays (default: [])
  targets     # Additional Rust targets (default: [])
  extras      # Extra components (default: [])
  variant     # Linux variant (default: "musl")
  config      # nixpkgs config (default: {})
}
```

**Example:**
```nix
rustPlatform = rustnix.lib.rust.mkRustPlatform {
  system = "x86_64-linux";
  nixpkgs = inputs.nixpkgs;
  targets = [ "aarch64-unknown-linux-musl" ];
  extras = [ "clippy" ];
};

# Use it
myPackage = rustPlatform.buildRustPackage {
  pname = "my-package";
  version = "0.1.0";
  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;
};
```

### `overlays.fenix`

Direct access to the fenix overlay for consumers who need it:

```nix
pkgs = import nixpkgs {
  system = "x86_64-linux";
  overlays = [ rustnix.lib.rust.overlays.fenix ];
};
```

### `mkCrossPkgs`

Configure cross-compilation nixpkgs and toolchain for a specific target.

**Parameters:**
```nix
{
  system              # Build system (e.g., "x86_64-linux")
  target              # Target system (e.g., "aarch64-linux")
  nixpkgs             # nixpkgs flake input
  overlays            # List of nixpkgs overlays
  additionalTargets   # Extra Rust targets (default: [])
  linuxVariant        # "musl" or "gnu" (default: "musl")
}
```

**Returns:** `{ callPackage, pkgs, toolchain }`

### `mkPackageSet`

Assemble the final package attribute set from components.

**Parameters:**
```nix
{
  defaultPackage   # The default package derivation
  mainPackage      # The main (named) package derivation
  packageName      # Custom package name (default: null)
  aliases          # List of alias names (default: [])
}
```

**Returns:** `{ default = defaultPackage; } // optional named package // optional aliases`

## Complete Examples

### Multi-Architecture Build with flake-parts

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    rustnix.url = "github:ck3mp3r/flakes?dir=rustnix";
    rustnix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ { flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      perSystem = { pkgs, system, ... }: {
        packages = inputs.rustnix.lib.rust.buildTargetOutputs {
          inherit system pkgs;
          nixpkgs = inputs.nixpkgs;
          supportedTargets = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
          cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
          cargoLock = { lockFile = ./Cargo.lock; };
          src = ./.;
          overlays = [];
          archiveAndHash = false;
        };
      };
    };
}
```

This creates:
```
packages.x86_64-linux.default      # x86_64 Linux package
packages.aarch64-linux.default     # ARM64 Linux package
packages.aarch64-darwin.default    # ARM64 macOS package
packages.x86_64-darwin.default     # (empty, not in supportedTargets)
```

### With Archive and Custom Package Name

```nix
packages = inputs.rustnix.lib.rust.buildTargetOutputs {
  inherit system pkgs;
  nixpkgs = inputs.nixpkgs;
  supportedTargets = [ "x86_64-linux" "aarch64-linux" ];
  cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
  cargoLock = { lockFile = ./Cargo.lock; };
  src = ./.;
  overlays = [];
  archiveAndHash = true;  # Creates .tgz archive with hashes
  packageName = "my-tool";
  aliases = [ "mt" ];
};
# Returns: { default = archive; my-tool = archive; mt = archive; }
```

### Custom Rust Toolchain for Development

```nix
{
  perSystem = { system, ... }: {
    devShells.default = let
      pkgs = inputs.rustnix.lib.rust.mkPkgs {
        inherit system;
        nixpkgs = inputs.nixpkgs;
      };
      toolchain = inputs.rustnix.lib.rust.mkToolchain {
        inherit system;
        targets = [ "wasm32-unknown-unknown" ];
        extras = [ "rustfmt" "clippy" "rust-analyzer" ];
      };
    in pkgs.mkShellNoCC {
      packages = [ toolchain ];
    };
  };
}
```

### Using archiveAndHash Standalone

```nix
let
  pkgs = import nixpkgs { system = "x86_64-linux"; };
  myDrv = pkgs.stdenv.mkDerivation {
    name = "my-artifact";
    src = ./.;
    buildPhase = ":";
    installPhase = ''
      mkdir -p $out/bin
      echo "#!/bin/sh" > $out/bin/hello
      echo "echo 'Hello, world!'" >> $out/bin/hello
      chmod +x $out/bin/hello
    '';
  };
  archive = inputs.rustnix.lib.archiveAndHash {
    pkgs = pkgs;
    drv = myDrv;
    name = "my-artifact";
  };
in archive
```

### Using Platform Helpers

```nix
let
  utils = inputs.rustnix.lib.utils;
  systemInfo = utils.systemMap "x86_64-linux";
  targetTriple = utils.getTarget { system = "x86_64-linux"; variant = "musl"; };
in
  # systemInfo = { arch = "x86_64"; platform = "linux"; }
  # targetTriple = "x86_64-unknown-linux-musl"
```

## Cross-Compilation

Cross-compilation happens automatically when the build system differs from the target system. The library:

1. Checks if current `system` is in `supportedTargets`
2. If not supported, returns empty set `{}`
3. If supported, builds for the current system using appropriate toolchain
4. Handles musl static linking for Linux targets automatically

**Example:** Building on x86_64-linux for aarch64-linux:
- Build system: `x86_64-linux`
- Target system: `aarch64-linux`
- Library automatically configures cross-compilation toolchain

## Development

This flake includes a development shell with Rust stable toolchain from fenix:

```bash
nix develop
```

The dev shell includes:
- Rust stable toolchain (cargo, rustc, rust-std)
- Alejandra Nix formatter

## Notes

- **No `--no-pure-eval` needed**: Previous devenv dependency has been removed
- **fenix is internalized**: Consumers don't need to add fenix as a direct input
- **Static linking by default**: Linux targets use musl for static binaries
- **Per-system packages**: `buildTargetOutputs` only returns packages for the current system
- **packages.toolchain**: Pre-built stable Rust toolchain available as a flake package output (`inputs.rustnix.packages.${system}.toolchain`)

## Migration from Old API

If migrating from an older version of rustnix:

1. **Remove fenix input**: No longer needed as a direct input
2. **Remove devenv input**: No longer used
3. **Remove `--no-pure-eval`**: No longer required
4. **Update `buildTargetOutputs` calls**: Remove `fenix` parameter
5. **Update package structure expectations**: Packages are now per-system, not nested by target
6. **Add `overlays.fenix`**: If you need direct fenix access, use `rustnix.lib.rust.overlays.fenix`

See the source in `lib/` for more information on available helpers and detailed options.
