# Flakes Collection

A collection of useful Nix flakes providing packaged software and tools.

## Available Flakes

| Flake | Description | Quick Usage |
|-------|-------------|-------------|
| [☸️ k8s-utils](./k8s-utils/) | Comprehensive Kubernetes CLI tools bundle | `nix shell github:ck3mp3r/flakes?dir=k8s-utils` |
| [🤖 mods](./mods/) | AI on the command line | `nix run github:ck3mp3r/flakes?dir=mods` |
| [🪨 crush](./crush/) | Glamourous AI coding TUI agent | `nix run github:ck3mp3r/flakes?dir=crush` |
| [🌳 topiary-nu](./topiary-nu/) | Nushell formatting with tree-sitter | `nix run github:ck3mp3r/flakes?dir=topiary-nu` |
| [🧠 avante.nvim](./avante/) | AI-powered IDE features for Neovim | Neovim plugin |
| [🧰 nix-utils](./nix-utils/) | Reusable Nix library functions for Rust multiarch and artifact packaging | See [README](./nix-utils/README.md) |

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

Replace `<flake-name>` with `k8s-utils`, `mods`, `crush`, `topiary-nu`, or `nix-utils`.

## Contributing

Feel free to submit PRs for additional useful flakes or improvements to existing ones. Each flake should:

- Be self-contained in its own directory
- Include comprehensive documentation in its README
- Follow Nix best practices
- Include proper licensing information

## License

This repository is licensed under the Apache License 2.0. Individual packages may have their own licenses - see their respective documentation for details.
