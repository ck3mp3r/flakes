{
  description = "Slidev - Presentation slides for developers";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    slidev-src = {
      url = "github:slidevjs/slidev";
      flake = false;
    };
  };

  outputs = {
    nixpkgs,
    flake-utils,
    devshell,
    slidev-src,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      devshellPkgs = devshell.legacyPackages.${system};

      # Read package info from the CLI package
      packageJson = builtins.fromJSON (builtins.readFile "${slidev-src}/packages/slidev/package.json");

      # Use pnpm to fetch dependencies during fetch phase (network allowed)
      slidevDeps = pkgs.stdenvNoCC.mkDerivation {
        pname = "slidev-components";
        version = packageJson.version;

        dontUnpack = true;
        nativeBuildInputs = [pkgs.nodejs_24 pkgs.cacert];

        phases = ["fetchPhase" "installPhase"];
        fetchPhase = ''
          # Create temp directory for npm work
          TMPWORK=$(mktemp -d)
          export HOME=$TMPWORK
          cd $TMPWORK

          # Use npm to install packages
          npm install \
            --no-save \
            --install-strategy=shallow \
            @slidev/cli@${packageJson.version} \
            slidev-addon-excalidraw@1.0.4 \
            slidev-addon-tldraw@0.4.2 \
            slidev-addon-asciinema@0.1.11 \
            slidev-addon-components@0.0.1 \
            @slidev/theme-default \
            mermaid@11.10.1
        '';

        installPhase = ''
          mkdir -p $out
          cp -r node_modules $out/
        '';

        outputHashMode = "recursive";
        outputHashAlgo = "sha256";
        outputHash = "sha256-GeATC1TpMVPLBKa6iuArbbEKbt8ke2/PkDy5yRVhB9w=";
      };

      # Wrapper CLI that configures all the correct paths at execution time
      slidev = pkgs.stdenvNoCC.mkDerivation {
        pname = packageJson.name;
        version = packageJson.version;

        dontUnpack = true;
        nativeBuildInputs = [pkgs.makeWrapper];

        phases = ["installPhase"];
        installPhase = ''
          mkdir -p $out/bin $out/lib

          # Copy the fetched npm dependencies to the output
          cp -r ${slidevDeps}/* $out/lib/

          # Create wrapper that configures correct paths at execution time
          makeWrapper $out/lib/node_modules/.bin/slidev $out/bin/slidev \
            --suffix NODE_PATH : "$out/lib/node_modules" \
            --set NPM_CONFIG_CACHE "~/.cache/npm" \
            --set NPM_CONFIG_PREFIX "~/.local/share/npm" \
            --suffix NODE_PATH : "~/.local/share/npm/lib/node_modules" \
            --suffix PATH : "~/.local/share/npm/bin"
        '';

        meta = with pkgs.lib; {
          description = "Presentation slides for developers with addons";
          homepage = "https://sli.dev";
          license = licenses.mit;
          maintainers = [];
          platforms = platforms.all;
          mainProgram = "slidev";
        };
      };
    in {
      packages = {
        default = slidev;
        inherit slidev;
      };

      apps = {
        default = {
          type = "app";
          program = "${slidev}/bin/slidev";
        };
        slidev = {
          type = "app";
          program = "${slidev}/bin/slidev";
        };
      };

      devShells.default = devshellPkgs.mkShell {
        imports = [(devshellPkgs.importTOML ./devshell.toml)];
        packages = [slidev];
      };

      formatter = pkgs.alejandra;
    });
}
