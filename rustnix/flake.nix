{
  description = "A Nix flake with flake-utils, nixpkgs, and Alejandra for formatting.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }: let
    lib = {
      rust = import ./lib/rust;
      archiveAndHash = import ./lib/archiveAndHash.nix;
      utils = import ./lib/utils.nix;
    };
  in
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
    in {
      packages = {};
      formatter = pkgs.alejandra;

      # Tests for the rustnix library
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
    })
    // {
      lib = lib;
    };
}
