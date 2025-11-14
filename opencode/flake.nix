{
  description = "OpenCode with pre-populated cache including TUI binaries";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # TUI binaries from GitHub releases
    # Update tuiVersion below to change the version for all platforms
    tui-linux-x64 = {
      url = "https://github.com/sst/opencode/releases/download/v1.0.58/opencode-linux-x64.zip";
      flake = false;
    };
    tui-linux-arm64 = {
      url = "https://github.com/sst/opencode/releases/download/v1.0.58/opencode-linux-arm64.zip";
      flake = false;
    };
    tui-darwin-arm64 = {
      url = "https://github.com/sst/opencode/releases/download/v1.0.58/opencode-darwin-arm64.zip";
      flake = false;
    };
  };
  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];

      perSystem = {
        pkgs,
        system,
        ...
      }: let
        # TUI binary version - update this and the input URLs above when upgrading
        tuiVersion = "1.0.58";

        # Map system to the appropriate TUI binary input
        tuiBinary =
          {
            "x86_64-linux" = inputs.tui-linux-x64;
            "aarch64-linux" = inputs.tui-linux-arm64;
            "aarch64-darwin" = inputs.tui-darwin-arm64;
          }.${
            system
          } or (throw "Unsupported system: ${system}");

        # Derivation that runs opencode to populate the cache
        opencode-cache = pkgs.stdenv.mkDerivation {
          pname = "opencode-cache";
          version = pkgs.opencode.version;

          # No source needed, we're just capturing runtime data
          dontUnpack = true;

          nativeBuildInputs = [pkgs.opencode];

          buildPhase = ''
            # Set up a fake HOME for opencode to populate
            export HOME=$TMPDIR/home
            export XDG_CACHE_HOME=$TMPDIR/cache
            mkdir -p $HOME $XDG_CACHE_HOME

            # Trigger cache initialization by running opencode
            echo "Initializing opencode cache..."

            # Run models command to populate cache with models.json and package.json
            # This will create package.json with the exact versions OpenCode expects
            timeout 30s ${pkgs.opencode}/bin/opencode models > /dev/null 2>&1 || true

            # OpenCode creates package.json with auth plugins only
            # We need to also install the AI SDK packages that providers use
            cd $XDG_CACHE_HOME/opencode

            # First install what OpenCode generated (auth plugins with exact versions)
            ${pkgs.bun}/bin/bun install 2>&1 || true

            # Then add the AI SDK packages that providers need at runtime
            # These are loaded dynamically when a provider is first used
            ${pkgs.bun}/bin/bun add @ai-sdk/amazon-bedrock@latest @ai-sdk/anthropic@latest @ai-sdk/openai-compatible@latest @aws-sdk/credential-providers@latest 2>&1 || true

            # OpenCode calls BunProc.install(pkg, "latest") and checks if package.json[pkg] === "latest"
            # But bun add pkg@latest writes "^x.y.z" to package.json, not "latest"
            # We need to replace the version ranges with "latest" for SDK packages
            ${pkgs.jq}/bin/jq '
              .dependencies["@ai-sdk/amazon-bedrock"] = "latest" |
              .dependencies["@ai-sdk/anthropic"] = "latest" |
              .dependencies["@ai-sdk/openai-compatible"] = "latest" |
              .dependencies["@aws-sdk/credential-providers"] = "latest"
            ' package.json > package.json.tmp
            mv package.json.tmp package.json

            # List what was created
            echo "Cache contents:"
            find $XDG_CACHE_HOME -type f || true
          '';

          installPhase = ''
            mkdir -p $out

            # Copy the populated cache from XDG_CACHE_HOME (we control this variable)
            cp -r $XDG_CACHE_HOME/opencode/* $out/

            # Add the pre-downloaded TUI binary from flake input
            mkdir -p $out/tui
            echo "Adding TUI binary from: ${tuiBinary}"

            # The TUI binary input is already unpacked by Nix
            # Find and copy the opencode binary
            find ${tuiBinary} -name "opencode" -type f -perm -111 | head -1 | xargs -I {} cp {} $out/tui/tui-${tuiVersion}.

            chmod +x $out/tui/tui-${tuiVersion}.

            echo "TUI binary size: $(du -h $out/tui/tui-${tuiVersion}.)"
          '';
        };

        # Wrapper package that runs opencode with cache from Nix store
        # The cache must be copied to a writable location because opencode writes to it
        opencode-with-cache = pkgs.symlinkJoin {
          name = "opencode-with-cache-${pkgs.opencode.version}";

          paths = [pkgs.opencode opencode-cache];

          nativeBuildInputs = [pkgs.makeWrapper];

          postBuild = ''
            # Unwrap the original binary if it exists
            if [ -L $out/bin/opencode ]; then
              rm $out/bin/opencode
            fi

            # Set XDG_CACHE_HOME to ~/.cache-nix so opencode uses ~/.cache-nix/opencode
            makeWrapper ${pkgs.opencode}/bin/opencode $out/bin/opencode \
              --run 'export XDG_CACHE_HOME="$HOME/.cache-nix"' \
              --run 'mkdir -p "$XDG_CACHE_HOME/opencode"
                # Always update symlinks to point to current Nix store path
                # Remove old symlinks/dirs first to ensure clean state
                rm -f "$XDG_CACHE_HOME/opencode/tui"
                rm -f "$XDG_CACHE_HOME/opencode/node_modules"
                rm -f "$XDG_CACHE_HOME/opencode/models.json"
                rm -f "$XDG_CACHE_HOME/opencode/package.json"
                rm -f "$XDG_CACHE_HOME/opencode/bun.lock"
                # Create symlinks to Nix store (read-only resources)
                ln -s "'"$out"'/tui" "$XDG_CACHE_HOME/opencode/tui"
                ln -s "'"$out"'/node_modules" "$XDG_CACHE_HOME/opencode/node_modules"
                ln -s "'"$out"'/package.json" "$XDG_CACHE_HOME/opencode/package.json"
                ln -s "'"$out"'/bun.lock" "$XDG_CACHE_HOME/opencode/bun.lock"
                # Copy models.json (needs to be writable)
                cp "'"$out"'/models.json" "$XDG_CACHE_HOME/opencode/models.json"
                # Only copy version if it does not exist (writable file)
                if [ ! -f "$XDG_CACHE_HOME/opencode/version" ]; then
                  cp "'"$out"'/version" "$XDG_CACHE_HOME/opencode/version"
                fi'
          '';
        };
      in {
        formatter = pkgs.alejandra;
        packages.default = opencode-with-cache;

        apps.default = {
          type = "app";
          program = "${opencode-with-cache}/bin/opencode";
        };
      };
    };
}
