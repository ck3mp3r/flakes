{
  description = "Slidev - Presentation slides for developers";

  inputs = {
    base-nixpkgs.url = "path:../base-nixpkgs";
    nixpkgs.follows = "base-nixpkgs/unstable";
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

      slidev = pkgs.stdenv.mkDerivation {
        pname = packageJson.name;
        version = packageJson.version;

        # No source needed since we use npx
        dontUnpack = true;

        nativeBuildInputs = with pkgs; [
          nodejs_20
          makeWrapper
        ];

        # Simple installation that uses npx
        installPhase = ''
          runHook preInstall

          # Create the binary using makeWrapper
          mkdir -p $out/bin
          makeWrapper ${pkgs.nodejs_20}/bin/npx $out/bin/slidev \
            --add-flags "--yes @slidev/cli@${packageJson.version}" \
            --run "cd \$HOME"

          runHook postInstall
        '';

        meta = with pkgs.lib; {
          description = "Presentation slides for developers";
          longDescription = ''
            Slidev aims to provide the flexibility and interactivity for developers
            to make their presentations even more interesting, expressive, and attractive
            by using the tools and technologies they are already familiar with.
          '';
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
