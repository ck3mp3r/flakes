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
        nativeBuildInputs = extraArgs.nativeBuildInputs or [] 
          ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [pkgs.fixDarwinDylibNames];
        
        postInstall = pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
          ${pkgs.fixDarwinDylibNames}/bin/fixDarwinDylibNames $out/bin/*
        '';
      }
      // extraArgs);
in
  drv
