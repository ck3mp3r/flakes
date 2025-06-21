# Flakes Collection

A collection of useful Nix flakes providing packaged software and tools.

## Available Flakes

| Flake | Description | Quick Usage |
|-------|-------------|-------------|
| [☸️ k8s-utils](./k8s-utils/) | Comprehensive Kubernetes CLI tools bundle | `nix shell github:ck3mp3r/flakes?dir=kubernetes` |
| [🤖 mods](./mods/) | AI on the command line | `nix run github:ck3mp3r/flakes?dir=mods` |
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

Replace `<flake-name>` with `kubernetes`, `mods`, or `topiary-nu`.

## Detailed Documentation

Each flake has its own detailed README with usage examples, configuration instructions, and build information:

- **[k8s-utils/README.md](./k8s-utils/README.md)** - Complete documentation for Kubernetes CLI tools bundle
- **[mods/README.md](./mods/README.md)** - Complete documentation for the AI CLI tool
- **[topiary-nu/README.md](./topiary-nu/README.md)** - Complete documentation for Nushell formatting

## Repository Structure

```
├── k8s-utils/     # Kubernetes CLI tools bundle flake
│   ├── flake.nix
│   ├── flake.lock
│   └── README.md
├── mods/           # AI CLI tool flake
│   ├── flake.nix
│   ├── flake.lock
│   └── README.md
├── topiary-nu/     # Nushell formatter flake  
│   ├── flake.nix
│   ├── flake.lock
│   └── README.md
└── README.md       # This file
```

## Contributing

Feel free to submit PRs for additional useful flakes or improvements to existing ones. Each flake should:

- Be self-contained in its own directory
- Include comprehensive documentation in its README
- Follow Nix best practices
- Include proper licensing information

## License

This repository is licensed under the MIT License. Individual packages may have their own licenses - see their respective documentation for details.
