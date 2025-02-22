{
  description = "This flake wraps the topiary formatting functionality.";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
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

          buildInputs = [pkgs.tree-sitter pkgs.nodejs pkgs.gcc];

          buildPhase = ''
            tree-sitter generate
          '';

          installPhase = ''
            mkdir -p $out/lib
            gcc -shared -o $out/lib/tree_sitter_nu.so src/parser.c src/scanner.c -I./src
          '';
        };
      in {
        packages.default = pkgs.stdenvNoCC.mkDerivation {
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
      }
    );
}
