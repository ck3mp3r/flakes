{
  description = "This flake wraps the topiary formatting functionality.";
  inputs = {
    base-nixpkgs.url = "github:ck3mp3r/flakes?dir=base-nixpkgs";
    nixpkgs.follows = "base-nixpkgs/unstable";
    flake-utils.url = "github:numtide/flake-utils";
    tree-sitter-nu = {
      url = "github:nushell/tree-sitter-nu";
      flake = false;
    };
    topiary-nushell = {
      url = "github:blindFS/topiary-nushell";
      flake = false;
    };
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    tree-sitter-nu,
    topiary-nushell,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config = {allowUnfree = true;};
        };
        treeSitterNu = pkgs.stdenv.mkDerivation {
          name = "tree-sitter-nu";
          src = tree-sitter-nu;

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
          src = topiary-nushell;

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
      }
    )
    // {
      overlays.default = final: prev: {
        topiary-nu = self.packages.${final.system}.default;
      };
    };
}
