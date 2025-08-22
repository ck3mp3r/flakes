{
  description = "This flake wraps the charmbracelet/mods cli.";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    avante-src = {
      url = "github:yetone/avante.nvim?ref=v0.0.27";
      flake = false;
    };
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    fenix,
    avante-src,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      version = "avante-libs v0.0.27";
      pkgs = import nixpkgs {
        inherit system;
        config = {allowUnfree = true;};
      };
      fenixToolchain = fenix.packages.${system}.stable.toolchain;
      rustPlatform = pkgs.makeRustPlatform {
        cargo = fenixToolchain;
        rustc = fenixToolchain;
      };

      avante-nvim-lib = rustPlatform.buildRustPackage {
        pname = "avante-nvim-lib";
        src = avante-src;
        inherit version;

        cargoLock = {
          lockFile = avante-src + "/Cargo.lock";
          outputHashes = {
            "hf-hub-0.4.1" = "sha256-8IkbFytOolQGyEhGzjqVCguSLYaN6E8BUgekf1auZUk=";
          };
        };

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
          "--skip=test_hf"
          "--skip=test_public_url"
          "--skip=test_roundtrip"
          "--skip=test_fetch_md"
        ];
      };
      avante-nvim = pkgs.vimUtils.buildVimPlugin {
        pname = "avante.nvim";
        src = avante-src;
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
          inherit avante-nvim-lib;
        };

        nvimSkipModules = [
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
      formatter = pkgs.alejandra;
      packages.default = avante-nvim;
    })
    // {
      overlays.default = final: prev: {
        vimPlugins =
          prev.vimPlugins
          // {
            avante-nvim = self.packages.${final.system}.default;
          };
      };
    };
}
