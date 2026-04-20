{
  description = "A Nix flake with flake-parts, nixpkgs, and Alejandra for formatting.";

  inputs = {
    base-nixpkgs.url = "github:ck3mp3r/flakes?dir=base-nixpkgs";
    nixpkgs.follows = "base-nixpkgs/unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      flake = {
        lib = {
          rust = import ./lib/rust;
          archiveAndHash = import ./lib/archiveAndHash.nix;
          utils = import ./lib/utils.nix;
        };
      };

      perSystem = {
        system,
        inputs',
        ...
      }: let
        # Import nixpkgs with base-nixpkgs overlay
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [inputs.base-nixpkgs.overlays.default];
          config.allowUnfree = true;
        };
      in {
        packages = {};

        formatter = pkgs.alejandra;

        devShells.default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            alejandra
            inputs'.fenix.packages.stable.toolchain
          ];
        };

        checks = {
          cross-compilation-tests = let
            testResult = import ./tests/cross-compilation.nix {inherit pkgs;};
          in
            pkgs.runCommand "cross-compilation-tests" {} ''
              echo "Running cross-compilation tests..."
              echo '${builtins.toJSON testResult.runTests}' > $out
              echo "Cross-compilation tests passed!"
            '';

          usage-scenario-tests = let
            testResult = import ./tests/usage-scenarios.nix {inherit pkgs;};
          in
            pkgs.runCommand "usage-scenario-tests" {} ''
              echo "Running usage scenario tests..."
              echo '${builtins.toJSON testResult.validations}' > $out
              echo "Usage scenario tests passed!"
            '';

          utility-tests = let
            testResult = import ./tests/default.nix {inherit pkgs;};
          in
            pkgs.runCommand "utility-tests" {} ''
              echo "Running utility function tests..."
              echo '${builtins.toJSON testResult.validate}' > $out
              echo "Utility tests passed!"
            '';
        };
      };
    };
}
