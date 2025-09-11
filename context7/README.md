# Context7 MCP Server (Nix Package)

Nix flake for packaging the [Context7 MCP Server](https://github.com/upstash/context7).

## Installation

```bash
# Run directly
nix run github:ck3mp3r/flakes?dir=context7

# Install to profile  
nix profile install github:ck3mp3r/flakes?dir=context7

# Add to flake.nix
inputs.context7.url = "github:ck3mp3r/flakes?dir=context7";
# then use: inputs.context7.packages.${system}.default
```

## Usage

```bash
context7-mcp
```

## Package Details

- **Version**: 1.0.17
- **Build tools**: Node.js 20, TypeScript, Bun
- **Outputs**: `packages.{default,context7-mcp}`, `apps.default`, `overlays.default`

## License

MIT (same as upstream)
