{
  description = "This flake wraps the charmbracelet/mods cli.";
  inputs = {
    base-nixpkgs.url = "github:ck3mp3r/flakes?dir=base-nixpkgs";
    nixpkgs.follows = "base-nixpkgs/unstable";
    flake-utils.url = "github:numtide/flake-utils";
    mods-src = {
      url = "github:charmbracelet/mods";
      flake = false;
    };
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    mods-src,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config = {allowUnfree = true;};
        };
        mods = pkgs.buildGoModule rec {
          pname = "mods";
          version = "unstable-${pkgs.lib.substring 0 8 src.rev}";

          src = mods-src;
          vendorHash = null;
          proxyVendor = true;

          patches = [./patches/ollama-streaming-fix.patch];

          preBuild = ''
            export GOPROXY=https://proxy.golang.org
          '';

          ldflags = [
            "-s"
            "-w"
            "-X=main.Version=${version}"
          ];

          meta = with pkgs.lib; {
            description = "AI on the command line";
            homepage = "https://github.com/charmbracelet/mods";
            license = licenses.mit;
          };
        };
      in {
        formatter = pkgs.alejandra;
        packages.default = mods;
      }
    )
    // {
      overlays.default = final: prev: {
        mods = self.packages.${final.system}.default;
      };
    };
}
