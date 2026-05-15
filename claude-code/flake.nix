{
  description = "Claude Code CLI with auto-updater disabled for Nix";
  inputs = {
    base-nixpkgs.url = "github:ck3mp3r/flakes?dir=base-nixpkgs";
    nixpkgs.follows = "base-nixpkgs/unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Claude Code binaries from Anthropic CDN
    # Update claudeCodeVersion below when upgrading
    claude-code-linux-x64 = {
      url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/2.1.142/linux-x64/claude";
      flake = false;
    };
    claude-code-linux-arm64 = {
      url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/2.1.142/linux-arm64/claude";
      flake = false;
    };
    claude-code-darwin-arm64 = {
      url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/2.1.142/darwin-arm64/claude";
      flake = false;
    };
  };
  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];

      perSystem = {system, ...}: let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [inputs.base-nixpkgs.overlays.default];
          config.allowUnfree = true;
        };

        claudeCodeVersion = "2.1.142";

        # Map system to the appropriate binary input
        claudeBinary =
          {
            "x86_64-linux" = inputs.claude-code-linux-x64;
            "aarch64-linux" = inputs.claude-code-linux-arm64;
            "aarch64-darwin" = inputs.claude-code-darwin-arm64;
          }
          .${
            system
          }
          or (throw "Unsupported system: ${system}");

        # Default settings.json baked into the Nix store
        defaultSettings = pkgs.writeTextFile {
          name = "claude-code-settings";
          destination = "/settings.json";
          text = builtins.toJSON {
            env = {
              DISABLE_AUTOUPDATER = "1";
              DISABLE_INSTALLATION_CHECKS = "1";
              DISABLE_UPDATES = "1";
            };
          };
        };

        claude-code = pkgs.stdenv.mkDerivation {
          pname = "claude-code";
          version = claudeCodeVersion;

          # The flake input is a store path to the raw binary
          dontUnpack = true;

          nativeBuildInputs = with pkgs;
            [makeWrapper]
            ++ lib.optionals stdenv.isLinux [autoPatchelfHook];

          buildInputs = with pkgs;
            lib.optionals stdenv.isLinux [
              stdenv.cc.cc.lib
              zlib
            ];

          installPhase = ''
            runHook preInstall
            install -Dm755 ${claudeBinary} $out/bin/claude
            runHook postInstall
          '';

          postFixup = ''
            wrapProgram $out/bin/claude \
              --argv0 claude \
              --set DISABLE_AUTOUPDATER 1 \
              --set DISABLE_INSTALLATION_CHECKS 1 \
              --set DISABLE_UPDATES 1 \
              --run '
                CLAUDE_CONFIG_DIR="''${CLAUDE_CONFIG_DIR:-$HOME/.claude-nix}"
                export CLAUDE_CONFIG_DIR
                mkdir -p "$CLAUDE_CONFIG_DIR"
                # Symlink settings.json to immutable Nix store copy so users cannot modify it.
                # If it exists but is not a symlink to the current store path, replace it.
                _nix_settings="${defaultSettings}/settings.json"
                if [ ! -L "$CLAUDE_CONFIG_DIR/settings.json" ] || [ "$(readlink "$CLAUDE_CONFIG_DIR/settings.json")" != "$_nix_settings" ]; then
                  rm -f "$CLAUDE_CONFIG_DIR/settings.json"
                  ln -s "$_nix_settings" "$CLAUDE_CONFIG_DIR/settings.json"
                fi
              '
          '';

          # Don't strip - it's a Bun-compiled binary
          dontStrip = true;

          meta = {
            description = "Claude Code - agentic coding tool by Anthropic";
            homepage = "https://claude.ai/code";
            license = pkgs.lib.licenses.unfree;
            sourceProvenance = [pkgs.lib.sourceTypes.binaryNativeCode];
            mainProgram = "claude";
            platforms = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
          };
        };
      in {
        formatter = pkgs.alejandra;
        packages.default = claude-code;

        apps.default = {
          type = "app";
          program = "${claude-code}/bin/claude";
        };
      };
    };
}
