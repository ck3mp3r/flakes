{
  description = "Development environment for ck3mp3r/flakes monorepo";

  inputs = {
    # Use the local base-nixpkgs for consistent package versions
    base-nixpkgs.url = "path:./base-nixpkgs";

    # Flake-parts for modular flake structure
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "base-nixpkgs/unstable";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      perSystem = {system, ...}: let
        # Get packages from base-nixpkgs (unstable)
        pkgs = inputs.base-nixpkgs.legacyPackages.${system};
      in {
        # Provide pkgs to modules
        _module.args.pkgs = pkgs;

        # Use alejandra formatter from base-nixpkgs
        formatter = pkgs.alejandra;

        # Define the default development shell
        devShells.default = pkgs.mkShellNoCC {
          name = "flakes-monorepo";

          packages = with pkgs; [
            # Version control
            git

            # Nix tooling
            nix
            nixpkgs-fmt
            alejandra

            # CI/CD tooling
            act
            cachix

            # Nushell and modules
            nushell

            # GitHub CLI
            gh
          ];

          shellHook = ''
            echo ""
            echo "🚀 Welcome to ck3mp3r/flakes development environment!"
            echo ""
            echo "Using packages from: base-nixpkgs"
            echo "Nix flakes: base-nixpkgs, k8s-utils, opencode, rustnix, slidev, topiary-nu"
            echo ""
          '';
        };
      };
    };
}
