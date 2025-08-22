{
  description = "This flake wraps the charmbracelet/crush tui app.";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    crush-src = {
      url = "github:charmbracelet/crush";
      flake = false;
    };
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    crush-src,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config = {allowUnfree = true;};
        };
        crush = pkgs.buildGoModule rec {
          pname = "crush";
          version = "unstable-${pkgs.lib.substring 0 8 src.rev}";

          src = crush-src;
          vendorHash = null;
          proxyVendor = true;

          preBuild = ''
            export GOPROXY=https://proxy.golang.org
          '';
          doCheck = false;
          ldflags = [
            "-s"
            "-w"
            "-X=main.Version=${version}"
          ];

          meta = with pkgs.lib; {
            description = "AI on the command line";
            homepage = "The glamourous AI coding agent for your favourite terminal 💘";
            license = licenses.mit;
          };
        };
      in {
        formatter = pkgs.alejandra;
        packages.default = crush;
      }
    )
    // {
      overlays.default = final: prev: {
        crush = self.packages.${final.system}.default;
      };
    };
}
