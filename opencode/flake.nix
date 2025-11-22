{
  description = "OpenCode with pre-populated cache including TUI binaries";
  inputs = {
    base-nixpkgs.url = "path:../base-nixpkgs";
    nixpkgs.follows = "base-nixpkgs/unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # OpenCode and TUI binaries from GitHub releases
    # Update opencodeVersion below to change the version for all platforms
    opencode-linux-x64 = {
      url = "https://github.com/sst/opencode/releases/download/v1.0.98/opencode-linux-x64.tar.gz";
      flake = false;
    };
    opencode-linux-arm64 = {
      url = "https://github.com/sst/opencode/releases/download/v1.0.98/opencode-linux-arm64.tar.gz";
      flake = false;
    };
    opencode-darwin-arm64 = {
      url = "https://github.com/sst/opencode/releases/download/v1.0.98/opencode-darwin-arm64.zip";
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
        # OpenCode version - update this and the input URLs above when upgrading
        opencodeVersion = "1.0.98";

        # Map system to the appropriate opencode binary input
        opencodeBinary =
          {
            "x86_64-linux" = inputs.opencode-linux-x64;
            "aarch64-linux" = inputs.opencode-linux-arm64;
            "aarch64-darwin" = inputs.opencode-darwin-arm64;
          }.${
            system
          } or (throw "Unsupported system: ${system}");

        # Build opencode package from GitHub release binary
        opencode = pkgs.stdenv.mkDerivation {
          pname = "opencode";
          version = opencodeVersion;

          src = opencodeBinary;

          nativeBuildInputs = with pkgs; [unzip];

          dontBuild = true;

          installPhase = ''
            mkdir -p $out/bin
            # Find the opencode binary and install it
            find . -name "opencode" -type f -perm -111 | head -1 | xargs -I {} cp {} $out/bin/opencode
            chmod +x $out/bin/opencode
          '';

          meta = {
            description = "OpenCode CLI - AI coding agent";
            homepage = "https://github.com/sst/opencode";
            platforms = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
          };
        };

        # Derivation that runs opencode to populate the cache
        opencode-cache = pkgs.stdenv.mkDerivation {
          pname = "opencode-cache";
          version = opencode.version;

          # No source needed, we're just capturing runtime data
          dontUnpack = true;

          nativeBuildInputs = [opencode];

          buildPhase = ''
            # Set up a fake HOME for opencode to populate
            export HOME=$TMPDIR/home
            export XDG_CACHE_HOME=$TMPDIR/cache
            mkdir -p $HOME $XDG_CACHE_HOME

            # Trigger cache initialization by running opencode
            echo "Initializing opencode cache..."

            # Run models command to populate cache with models.json and package.json
            # This will create package.json with the exact versions OpenCode expects
            timeout 30s ${opencode}/bin/opencode models > /dev/null 2>&1 || true

            # Ensure the cache directory exists (create it if opencode didn't)
            mkdir -p $XDG_CACHE_HOME/opencode

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
          '';
        };

        # Wrapper package that runs opencode with cache from Nix store
        # The cache must be copied to a writable location because opencode writes to it
        opencode-with-cache = pkgs.symlinkJoin {
          name = "opencode-with-cache-${opencode.version}";

          paths = [opencode opencode-cache];

          nativeBuildInputs = [pkgs.makeWrapper];

          postBuild = ''
            # Unwrap the original binary if it exists
            if [ -L $out/bin/opencode ]; then
              rm $out/bin/opencode
            fi

            # Set XDG_CACHE_HOME to ~/.cache-nix so opencode uses ~/.cache-nix/opencode
            makeWrapper ${opencode}/bin/opencode $out/bin/opencode \
              --run 'export XDG_CACHE_HOME="$HOME/.cache-nix"' \
              --run 'mkdir -p "$XDG_CACHE_HOME/opencode"
                # Always update symlinks to point to current Nix store path
                # Remove old symlinks/dirs first to ensure clean state
                rm -f "$XDG_CACHE_HOME/opencode/node_modules"
                rm -f "$XDG_CACHE_HOME/opencode/models.json"
                rm -f "$XDG_CACHE_HOME/opencode/package.json"
                rm -f "$XDG_CACHE_HOME/opencode/bun.lock"
                # Create symlinks to Nix store (read-only resources)
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
