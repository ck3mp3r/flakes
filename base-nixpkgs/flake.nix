{
  description = "Pinned versions of nixpkgs (unstable and stable) for use across multiple projects";
  inputs = {
    unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    stable.url = "github:nixos/nixpkgs/release-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      perSystem = {system, ...}: let
        pkgs = import inputs.unstable {
          inherit system;
          config = {allowUnfree = true;};
        };
      in {
        formatter = pkgs.alejandra;
        legacyPackages = pkgs;
      };
    };
}
