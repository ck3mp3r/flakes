{
  description = "A Nix flake with flake-utils and nixpkgs, ready for local development";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};
      in {
        # Export library functions
        lib = {
          semver-version = import ./lib/semver-version.nix;
          rust-multiarch = import ./lib/rust-multiarch.nix;
        };
      }
    );
}
