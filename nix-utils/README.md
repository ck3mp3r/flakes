# nix-utils

Reusable Nix library functions for multi-architecture Rust builds and artifact packaging.

## Provided Utilities

- **rustMultiarch**: Build Rust projects for multiple architectures (native and cross) using Fenix and overlays. Optionally archives and hashes outputs for easy distribution and verification.
- **archiveAndHash**: Wraps any build output, producing a directory with a `.tgz` archive, a Nix-style hash, and a regular SHA256 hash, all with human-friendly names.

## Usage

Add this flake as an input to your own flake:

```nix
inputs.nix-utils.url = "github:ck3mp3r/flakes?dir=nix-utils&ref=main";
```

Then use the utilities in your `flake.nix`:

```nix
rustMultiarch = nix-utils.lib.rustMultiarch { ... };
```

To enable artifact archiving and hashing:

```nix
rustMultiarch = nix-utils.lib.rustMultiarch {
  ...
  archiveAndHash = true;
};
```
