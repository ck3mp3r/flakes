{
  description = "This flake wraps the topiary formatting functionality.";
  inputs = {
    base-nixpkgs.url = "github:ck3mp3r/flakes?dir=base-nixpkgs";
    nixpkgs.follows = "base-nixpkgs/unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    tree-sitter-nu = {
      url = "github:nushell/tree-sitter-nu";
      flake = false;
    };
    topiary-nushell = {
      url = "github:blindFS/topiary-nushell";
      flake = false;
    };
  };
  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      perSystem = {pkgs, ...}: let
        treeSitterNu = pkgs.stdenv.mkDerivation {
          name = "tree-sitter-nu";
          src = inputs.tree-sitter-nu;

          buildInputs = [pkgs.tree-sitter pkgs.nodejs];

          buildPhase = ''
            tree-sitter generate --abi=14
          '';

          installPhase = ''
            mkdir -p $out/lib
            NIX_LDFLAGS="-rpath $out/lib"
            $CC $CFLAGS $NIX_LDFLAGS -shared -o $out/lib/tree_sitter_nu.so src/parser.c src/scanner.c -I./src
          '';
        };

        topiaryNu = pkgs.stdenvNoCC.mkDerivation {
          name = "topiary-nu";
          src = inputs.topiary-nushell;

          buildPhase = ''
            mkdir $out
            cat <<EOF > $out/languages.ncl
            {
              languages = {
                nu = {
                  extensions = ["nu"],
                  grammar.source.path = "${treeSitterNu}/lib/tree_sitter_nu.so"
                },
              },
            }
            EOF
          '';

          installPhase = ''
            cp -r $src/languages $out
          '';
        };
      in {
        formatter = pkgs.alejandra;
        packages.default = topiaryNu;
      };

      flake = {
        overlays.default = final: prev: {
          topiary-nu = inputs.self.packages.${final.system}.default;
        };
      };
    };
}
