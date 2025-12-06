# OpenCode with Pre-populated Cache

OpenCode - The AI coding agent built for the terminal, packaged with pre-populated cache.

## Overview

This flake wraps the existing [OpenCode](https://opencode.ai) package from nixpkgs and captures its runtime cache during the build phase. The cache is then bundled in the Nix store and automatically deployed on first run.

## Features

- **Uses upstream nixpkgs package**: No custom build, just wraps the official package
- **Pre-populated cache**: Runs opencode during build to capture cache data
- **Cache initialization**: Automatically sets up `~/.cache/opencode` from Nix store on first run
- **XDG compliant**: Respects `XDG_CACHE_HOME` environment variable
- **Works in restricted environments**: All data pre-built, no runtime downloads needed

## Usage

### Run directly

```bash
nix run github:ck3mp3r/flakes?dir=opencode
```

### Install to profile

```bash
nix profile install github:ck3mp3r/flakes?dir=opencode
```

### Use in your flake

```nix
{
  inputs = {
    opencode.url = "github:ck3mp3r/flakes?dir=opencode";
  };

  outputs = { self, nixpkgs, opencode }: {
    # Use in your configuration
    packages.x86_64-linux.default = opencode.packages.x86_64-linux.default;
  };
}
```

## How it works

The flake creates two derivations:

### 1. `opencode-cache` (build-time)

During the Nix build:
1. Sets up a temporary HOME directory
2. Runs opencode commands to trigger cache population
3. Captures what can be pre-populated: `models.json` (~416KB), `node_modules` (~6MB), `bun.lock`, `package.json`
4. Stores the captured cache in the Nix store at `$out/`
5. Includes the platform-specific TUI binary for your system architecture

### 2. `opencode-with-cache` (runtime)

The main package wraps the upstream opencode binary:
1. On every run, ensures `~/.cache-nix/opencode` is properly set up
2. Always updates symlinks to point to the current Nix store path:
   - Symlinks to read-only components in Nix store (tui, node_modules, package.json, bun.lock)
   - Copies writable files (models.json, version file) if they don't exist
3. Launches the real opencode binary

This hybrid approach minimizes disk usage while providing all necessary data and ensures the cache always points to the correct Nix store generation.

## Complete Cache Pre-population with Smart Symlinking

This flake pre-populates **everything** OpenCode needs (~97MB in Nix store):
- **TUI binary** (81MB) - Platform-specific for your architecture, fetched from GitHub releases as flake inputs
- **node_modules** (~15MB) - Runtime dependencies including all provider auth plugins:
  - `@ai-sdk/amazon-bedrock` - Amazon Bedrock provider
  - `@ai-sdk/anthropic` - Anthropic/Claude provider
  - `@ai-sdk/openai-compatible` - OpenAI-compatible providers (including GitHub Copilot)
  - `@aws-sdk/credential-providers` - AWS credential handling
  - `opencode-copilot-auth` - GitHub Copilot authentication plugin
  - `opencode-anthropic-auth` - Anthropic authentication plugin
- **models.json** (416KB) - Model configurations for all providers
- **bun.lock, package.json, version** - Metadata files

Everything is downloaded and stored in the Nix store at build time, so OpenCode works in completely offline/restricted environments.

### Efficient Storage Strategy

The wrapper automatically maintains `~/.cache-nix/opencode` on every run with:
- **Symlinks** to large read-only components (tui, node_modules, package.json, bun.lock) - ~96MB in Nix store, ~0 bytes copied
- **Copies** writable files (models.json, version, logs, sessions) - ~420KB disk usage

This means you get the full 97MB cache with only ~420KB actual disk usage in your home directory! The symlinks are always refreshed to point to the current Nix store generation, ensuring consistency across updates.

**Note**: Uses `~/.cache-nix/opencode` instead of `~/.cache/opencode` to avoid conflicts with existing OpenCode installations.

### How Package Installation is Avoided

OpenCode's provider system dynamically loads npm packages when a model is used. The install check is:

```typescript
if (parsed.dependencies[pkg] === version) return mod
```

This means the package.json version string must exactly match what OpenCode requests. The flake handles this by:

1. Running `opencode models` to generate package.json with exact auth plugin versions (e.g., `"opencode-copilot-auth": "0.0.4"`)
2. Installing AI SDK packages that providers need (`@ai-sdk/openai-compatible`, etc.)
3. Patching package.json to replace SDK package versions with `"latest"` (since OpenCode calls `BunProc.install(pkg, "latest")`)

This ensures all packages are pre-installed and OpenCode never tries to run `bun install` at runtime.

## Customizing Cache Population

If you need to run specific commands to populate the cache, edit the `buildPhase` in the `opencode-cache` derivation:

```nix
buildPhase = ''
  export HOME=$TMPDIR/home
  export XDG_CACHE_HOME=$TMPDIR/cache
  mkdir -p $HOME $XDG_CACHE_HOME

  # Add your initialization commands here
  ${pkgs.opencode}/bin/opencode init
  ${pkgs.opencode}/bin/opencode download-models
  # etc.
'';
```

## Configuration

The cache location can be customized via `XDG_CACHE_HOME`:

```bash
XDG_CACHE_HOME=/custom/path nix run github:ck3mp3r/flakes?dir=opencode
```

## Supported Providers

The pre-populated cache includes authentication plugins and SDK adapters for:

- **GitHub Copilot** (`github-copilot`) - 12 models including GPT-5, Claude Sonnet 4.5, Grok, Gemini 2.5 Pro
- **Anthropic** (`anthropic`) - Claude Opus 4, Sonnet, Haiku models
- **Amazon Bedrock** (`bedrock`) - AWS-hosted AI models
- **OpenAI-compatible** - Any OpenAI API-compatible provider

All provider dependencies are installed at build time, so you can use any supported provider without additional downloads.

### Usage Examples

To use a specific model, specify it with the `-m` flag:

```bash
# GitHub Copilot models (note: provider ID is 'github-copilot', not 'copilot')
nix run .# -- run -m github-copilot/gpt-4.1 "hello"
nix run .# -- run -m github-copilot/gpt-5 "hello"
nix run .# -- run -m github-copilot/claude-sonnet-4.5 "hello"

# Anthropic models
nix run .# -- run -m anthropic/claude-opus-4-1 "hello"

# List all available models
nix run .# -- models
```

**Important**: The GitHub Copilot provider ID is `github-copilot`, not `copilot`. If you have a config file at `~/.config/opencode/opencode.json` with `"model": "copilot/..."`, you need to update it to `"model": "github-copilot/..."`.

## Package

This flake provides a single package: `default` - OpenCode with pre-populated cache (97MB total)

## Updating

To update to a newer version:

1. Run `nix flake update` in this directory
2. The flake will automatically use the latest opencode from nixpkgs-unstable

## Updating to a New Version

To update to a newer version of OpenCode TUI binaries:

1. Check for new releases at https://github.com/sst/opencode/releases
2. Update `flake.nix`:
   - Change the `tuiVersion` variable (around line 29)
   - Update the TUI binary URLs in the inputs section to match the new version
3. Run `nix flake update` to fetch new binaries and update the lock file
4. Rebuild: `nix build`

Example:
```nix
# In flake.nix perSystem let block:
tuiVersion = "1.0.59";  # Update this

# In inputs section:
tui-darwin-arm64 = {
  url = "https://github.com/sst/opencode/releases/download/v1.0.59/opencode-darwin-arm64.zip";
  flake = false;
};
# ... repeat for other platforms
```

The TUI binaries are architecture-specific and automatically selected based on your system.

## License

OpenCode is licensed under the MIT License. See the [upstream repository](https://github.com/sst/opencode) for details.
