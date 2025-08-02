{
  description = "A Nix flake with flake-utils, nixpkgs, and Alejandra for formatting.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }: let
    lib = {
      rustMultiarch = import ./lib/rustMultiarch.nix;
      archiveAndHash = import ./lib/archiveAndHash.nix;
    };
  in
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
    in {
      packages = {};
      formatter = pkgs.alejandra;
    })
    // {
      lib = lib;
    };
}
