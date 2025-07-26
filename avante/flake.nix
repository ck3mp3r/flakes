{
  description = "This flake wraps the charmbracelet/mods cli.";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    avante-src = {
      url = "github:yetone/avante.nvim?ref=v0.0.26";
      flake = false;
    };
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    avante-src,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        version = "avante-libs v0.0.26";
        pkgs = import nixpkgs {
          inherit system;
          config = {allowUnfree = true;};
        };
        avante-nvim-lib = pkgs.rustPlatform.buildRustPackage {
          pname = "avante-nvim-lib";
          src = avante-src;
          inherit version;

          useFetchCargoVendor = true;
          cargoHash = "sha256-8mBpzndz34RrmhJYezd4hLrJyhVL4S4IHK3plaue1k8=";

          nativeBuildInputs = with pkgs; [
            pkg-config
            makeWrapper
            perl
          ];

          buildInputs = with pkgs; [
            openssl
          ];

          buildFeatures = ["luajit"];

          checkFlags = [
            # Disabled because they access the network.
            "--skip=test_hf"
            "--skip=test_public_url"
            "--skip=test_roundtrip"
            "--skip=test_fetch_md"
          ];
        };
        avante-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "avante.nvim";
          src = avante-nvim-lib;
          inherit version;

          dependencies = with pkgs.vimPlugins; [
            dressing-nvim
            img-clip-nvim
            nui-nvim
            nvim-treesitter
            plenary-nvim
          ];

          postInstall = let
            ext = pkgs.stdenv.hostPlatform.extensions.sharedLibrary;
          in ''
            mkdir -p $out/build
            ln -s ${avante-nvim-lib}/lib/libavante_repo_map${ext} $out/build/avante_repo_map${ext}
            ln -s ${avante-nvim-lib}/lib/libavante_templates${ext} $out/build/avante_templates${ext}
            ln -s ${avante-nvim-lib}/lib/libavante_tokenizers${ext} $out/build/avante_tokenizers${ext}
            ln -s ${avante-nvim-lib}/lib/libavante_html2md${ext} $out/build/avante_html2md${ext}
          '';

          passthru = {
            updateScript = pkgs.nix-update-script {
              extraArgs = ["--version=branch"];
              attrPath = "vimPlugins.avante-nvim.avante-nvim-lib";
            };

            # needed for the update script
            inherit avante-nvim-lib;
          };

          nvimSkipModules = [
            # Requires setup with corresponding provider
            "avante.providers.azure"
            "avante.providers.copilot"
            "avante.providers.gemini"
            "avante.providers.ollama"
            "avante.providers.vertex"
            "avante.providers.vertex_claude"
          ];

          meta = {
            description = "Neovim plugin designed to emulate the behaviour of the Cursor AI IDE";
            homepage = "https://github.com/yetone/avante.nvim";
          };
        };
      in {
        packages.default = avante-nvim;
      }
    )
    // {
      overlays.default = final: prev: {
        avante-nvim = self.packages.${final.system}.default;
      };
    };
}
