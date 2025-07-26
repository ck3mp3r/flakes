# avante.nvim

A Nix flake for [avante.nvim](https://github.com/yetone/avante.nvim) — AI-powered IDE features for Neovim, inspired by Cursor AI.

## What is avante.nvim?

`avante.nvim` is a Neovim plugin that brings advanced AI IDE features to your editor, including code chat, planning, refactoring, and context-aware suggestions using providers like OpenAI, Anthropic Claude, Copilot, and more.

## How to use this flake

You can use this flake to provide the avante.nvim plugin for Neovim in your Nix-based configuration. For example, to build the plugin:

```bash
nix build .#avante-nvim
```

### Example: Use the overlay in another flake

To use avante.nvim from this flake in another Nix flake, add it to your `inputs` and apply the overlay:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    avante.url = "github:ck3mp3r/flakes?dir=avante";
  };

  outputs = { self, nixpkgs, avante, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ avante.overlays.default ];
      };
    in {
      packages.avante-nvim = pkgs.avante-nvim;
    };
}
```

After applying the overlay, `pkgs.avante-nvim` is available as a package and can be used in your Neovim configuration or elsewhere in your Nix setup.

## Upstream

- **Source**: [yetone/avante.nvim](https://github.com/yetone/avante.nvim)
- **License**: Apache-2.0
