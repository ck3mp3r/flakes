{
  description = "This flake wraps kcl and kcl-language-server functionality.";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    kcl-language-server = {
      url = "github:kcl-lang/kcl";
      flake = false;
    };
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    kcl-language-server,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config = {allowUnfree = true;};
        };

        cargoToml = builtins.fromTOML (builtins.readFile "${kcl-language-server}/kclvm/Cargo.toml");

        kcl-language-server' = pkgs.rustPlatform.buildRustPackage {
          name = cargoToml.package.name;
          version = cargoToml.package.version;

          srcRoot = "${kcl-language-server}";
          src = "${kcl-language-server}/kclvm";

          cargoLock = {
            lockFile = "${kcl-language-server}/kclvm/Cargo.lock";
            outputHashes = {
              "inkwell-0.2.0" = "sha256-JxSlhShb3JPhsXK8nGFi2uGPp8XqZUSiqniLBrhr+sM=";
              "protoc-bin-vendored-3.2.0" = "sha256-cYLAjjuYWat+8RS3vtNVS/NAJYw2NGeMADzGBL1L2Ww=";
            };
          };

          PROTOC = "${pkgs.protobuf}/bin/protoc";
          PROTOC_INCLUDE = "${pkgs.protobuf}/include";

          buildAndTestSubdir = "tools/src/LSP";

          buildPhaseCargoFlags = [
            "--profile"
            "release"
            "--offline"
          ];

          nativeBuildInputs = with pkgs; [
            git
            pkg-config
            protobuf
          ];

          doCheck = false;
        };

        kcl-bundle = pkgs.buildEnv {
          name = "kcl-utils";
          paths = with pkgs; [
            kcl
            kcl-language-server'
          ];
          pathsToLink = ["/bin" "/share"];
        };
      in {
        packages.default = kcl-bundle;
        packages.kcl-language-server = kcl-language-server';
      }
    )
    // {
      overlays.default = final: prev: {
        kcl-utils = self.packages.${final.system}.default;
      };
    };
}
