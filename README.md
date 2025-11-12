# Flakes Collection

A collection of useful Nix flakes providing packaged software and tools.

## Available Flakes

| Flake | Description | Quick Usage |
|-------|-------------|-------------|
| [☸️ k8s-utils](./k8s-utils/) | Comprehensive Kubernetes CLI tools bundle | `nix shell github:ck3mp3r/flakes?dir=k8s-utils` |
| [🤖 mods](./mods/) | AI on the command line | `nix run github:ck3mp3r/flakes?dir=mods` |
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

Replace `<flake-name>` with `k8s-utils`, `mods`, `topiary-nu`, `rustnix`, `slidev`, or `opencode`.

## Contributing

Feel free to submit PRs for additional useful flakes or improvements to existing ones. Each flake should:

- Be self-contained in its own directory
- Include comprehensive documentation in its README
- Follow Nix best practices
- Include proper licensing information

## License

This repository is licensed under the Apache License 2.0. Individual packages may have their own licenses - see their respective documentation for details.
