{
  description = "Pinned versions of nixpkgs (unstable and stable) for use across multiple projects";
  inputs = {
    unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    stable.url = "github:nixos/nixpkgs/release-26.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      # this allows overriding any package in case of upstream issues
      flake.overlays.default = final: prev: {
      };

      perSystem = {system, ...}: let
        pkgs = import inputs.unstable {
          inherit system;
          config = {allowUnfree = true;};
          overlays = [inputs.self.overlays.default];
        };
      in {
        formatter = pkgs.alejandra;
        legacyPackages = pkgs;
        packages.nushell = pkgs.nushell;
      };
    };
}
