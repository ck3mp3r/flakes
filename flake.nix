{
  description = "Development environment for ck3mp3r/flakes monorepo";

  inputs = {
    # Use the local base-nixpkgs for consistent package versions
    base-nixpkgs.url = "path:./base-nixpkgs";

    # Devenv for development shells
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "base-nixpkgs/unstable";

    # Flake-parts for modular flake structure
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "base-nixpkgs/unstable";

    # Git hooks for pre-commit
    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "base-nixpkgs/unstable";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.devenv.flakeModule
        inputs.git-hooks.flakeModule
      ];

      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      perSystem = {
        config,
        system,
        ...
      }: let
        # Get packages from base-nixpkgs (unstable)
        pkgs = inputs.base-nixpkgs.legacyPackages.${system};
      in {
        # Provide pkgs to modules
        _module.args.pkgs = pkgs;

        # Use alejandra formatter from base-nixpkgs
        formatter = pkgs.alejandra;

        # Define the default development shell
        devenv.shells.default = {
          name = "flakes-monorepo";

          # Use packages from base-nixpkgs
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

          # Environment variables
          env = {
            FLAKE_ROOT = config.devenv.shells.default.devenv.root;
          };

          # Scripts available in the shell
          scripts = {
            build-all.exec = ''
              echo "Building all flakes..."
              for flake in */flake.nix; do
                dir=$(dirname "$flake")
                echo "Building $dir..."
                nix build "./$dir"
              done
            '';

            # List all available workflows
            workflows-list.exec = ''
              echo "📋 Available GitHub Actions workflows:"
              echo ""
              act -l
            '';

            # Run the build-and-cache workflow (actually builds, won't push to cache on non-main branch)
            workflows-build-cache.exec = ''
              echo "🏗️  Running build-and-cache workflow in container..."
              echo "   (Builds packages, uses --dry-run for cache push on non-main branch)"
              echo ""
              act workflow_dispatch -W .github/workflows/build-and-cache.yaml
            '';

            # Validate workflow syntax without execution (act -n flag)
            workflows-build-cache-validate.exec = ''
              echo "🔍 Validating build-and-cache workflow syntax..."
              echo "   (Does NOT execute, only checks syntax)"
              echo ""
              act workflow_dispatch -W .github/workflows/build-and-cache.yaml -n
            '';

            # Run specific workflow by name
            workflows-run.exec = ''
              if [ -z "$1" ]; then
                echo "Usage: workflows-run <workflow-file>"
                echo ""
                echo "Available workflows:"
                ls -1 .github/workflows/
                exit 1
              fi
              echo "🚀 Running workflow: $1"
              echo ""
              act workflow_dispatch -W ".github/workflows/$1"
            '';
          };

          # Enter shell message
          enterShell = ''
            echo ""
            echo "🚀 Welcome to ck3mp3r/flakes development environment!"
            echo ""
            echo "Available commands:"
            echo "  build-all                      - Build all flakes in the monorepo"
            echo ""
            echo "Workflow commands:"
            echo "  workflows-list                 - List all available workflows"
            echo "  workflows-build-cache          - Run build-and-cache (builds in container)"
            echo "  workflows-build-cache-validate - Validate syntax only (no execution)"
            echo "  workflows-run <file>           - Run specific workflow file"
            echo ""
            echo "Using packages from: base-nixpkgs"
            echo "Nix flakes: base-nixpkgs, k8s-utils, opencode, rustnix, slidev, topiary-nu"
            echo ""
          '';

          # Disable process-compose (we don't need background processes)
          processes = {};

          # Disable containers (we don't need them)
          containers = pkgs.lib.mkForce {};

          # Cachix integration for binary caching
          cachix.enable = true;
          cachix.pull = ["devenv"];

          # Enable direnv integration
          dotenv.enable = true;

          # Git hooks / pre-commit configuration
          git-hooks.hooks = {
            # Nix formatting
            alejandra.enable = true;

            # Nix linting
            statix.enable = true;

            # YAML validation (for GitHub workflows)
            check-yaml.enable = true;

            # Basic file hygiene
            end-of-file-fixer.enable = true;
            trim-trailing-whitespace = {
              enable = true;
              excludes = [".*\\.nix"];
            };
          };
        };
      };
    };
}
