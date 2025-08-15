{
  cargoLock,
  cargoToml,
  extraArgs ? {},
  pkgs,
  src,
  toolchain,
}: let
  pname = cargoToml.package.name;
  version = cargoToml.package.version;

  drv =
    (pkgs.makeRustPlatform {
      cargo = toolchain;
      rustc = toolchain;
    }).buildRustPackage ({
        inherit
          pname
          version
          src
          cargoLock
          ;
        buildInputs = extraArgs.buildInputs or [];
      }
      // extraArgs);
in
  drv
