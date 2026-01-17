{
  description = "Apple Container - A container platform for macOS";
  inputs = {
    base-nixpkgs.url = "github:ck3mp3r/flakes?dir=base-nixpkgs";
    nixpkgs.follows = "base-nixpkgs/unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Apple Container package from GitHub releases
    apple-container-pkg = {
      url = "https://github.com/apple/container/releases/download/0.7.1/container-installer-signed.pkg";
      flake = false;
    };
  };
  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["aarch64-darwin" "x86_64-darwin"];

      perSystem = {system, ...}: let
        # Import nixpkgs with allowUnfree
        pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        # Download and extract the precompiled container package
        apple-container = pkgs.stdenv.mkDerivation {
          pname = "apple-container";
          version = "0.7.1";

          src = inputs.apple-container-pkg;

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
        formatter = pkgs.alejandra;

        packages.default = apple-container;

        apps.default = {
          type = "app";
          program = "${apple-container}/bin/container";
        };
      };
    };
}
