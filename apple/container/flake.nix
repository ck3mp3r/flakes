{
  description = "Apple Container - A container platform for macOS";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    devshell.url = "github:numtide/devshell";
  };
  outputs = {
    nixpkgs,
    flake-utils,
    devshell,
    ...
  }:
    flake-utils.lib.eachSystem ["aarch64-darwin" "x86_64-darwin"] (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            devshell.overlays.default
          ];
        };

        # Download and extract the precompiled container package
        apple-container = pkgs.stdenv.mkDerivation {
          pname = "apple-container";
          version = "0.3.0";

          src = pkgs.fetchurl {
            url = "https://github.com/apple/container/releases/download/0.3.0/container-0.3.0-installer-signed.pkg";
            sha256 = "D3oAhATmZhGA6mehw6UEAY5Xwu8jjvTNqNcPKBUWxuY="; # Need actual hash
          };

          nativeBuildInputs = with pkgs; [
            xar
            cpio
          ];

          unpackPhase = ''
            xar -xf $src
            # Extract the payload
            cat Payload | gunzip -dc | cpio -i
          '';

          installPhase = ''
            mkdir -p $out/bin
            # Find and copy the container executable
            find . -name "container" -type f -executable -exec cp {} $out/bin/ \;
          '';

          meta = with pkgs.lib; {
            description = "Apple Container - A container platform for macOS 26";
            homepage = "https://github.com/apple/container";
            platforms = platforms.darwin;
            license = licenses.unfree;
          };
        };
      in {
        devShells.default = pkgs.devshell.mkShell {
          imports = [(pkgs.devshell.importTOML ./devshell.toml)];
          packages = with pkgs; [
            apple-container
          ];
        };

        packages = {
          default = apple-container;
        };

        apps = {
          default = {
            type = "app";
            program = "${apple-container}/bin/container";
          };
        };
      }
    );
}
