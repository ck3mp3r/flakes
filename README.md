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
| [🧰 rustnix](./rustnix/) | Reusable Nix library functions for Rust multiarch and artifact packaging | See [README](./rustnix/README.md) |
| [📊 slidev](./slidev/) | Presentation slides for developers | `nix run github:ck3mp3r/flakes?dir=slidev` |
| [🤖 context7](./context7/) | Context7 MCP Server for AI-powered contextual assistance | `nix run github:ck3mp3r/flakes?dir=context7` |
| [💻 opencode](./opencode/) | AI coding agent with pre-populated cache and offline support | `nix run github:ck3mp3r/flakes?dir=opencode` |

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

Replace `<flake-name>` with `k8s-utils`, `mods`, `crush`, `topiary-nu`, `rustnix`, `slidev`, `context7`, or `opencode`.

## Contributing

Feel free to submit PRs for additional useful flakes or improvements to existing ones. Each flake should:

- Be self-contained in its own directory
- Include comprehensive documentation in its README
- Follow Nix best practices
- Include proper licensing information

## License

This repository is licensed under the Apache License 2.0. Individual packages may have their own licenses - see their respective documentation for details.
