# avante.nvim

A Nix flake for [avante.nvim](https://github.com/yetone/avante.nvim) — AI-powered IDE features for Neovim, inspired by Cursor AI.

## What is avante.nvim?

`avante.nvim` is a Neovim plugin that brings advanced AI IDE features to your editor, including code chat, planning, refactoring, and context-aware suggestions using providers like OpenAI, Anthropic Claude, Copilot, and more.

## How to use this flake

You can use this flake to build the avante.nvim plugin:

```bash
nix build .#avante-nvim
```

### Example: Use the overlay in another flake

This flake provides an overlay that exposes `avante-nvim` as a plugin in `pkgs.vimPlugins`. To use it in another flake, add it to your `inputs` and apply the overlay:

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
      # You can now use pkgs.vimPlugins.avante-nvim in your Neovim configuration
      neovimWithAvante = pkgs.neovim.override {
        plugins = [ pkgs.vimPlugins.avante-nvim ];
      };
    };
}
```

After applying the overlay, use `pkgs.vimPlugins.avante-nvim` directly in your configuration.

## Upstream

- **Source**: [yetone/avante.nvim](https://github.com/yetone/avante.nvim)
- **License**: Apache-2.0
