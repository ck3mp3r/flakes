let
  buildPackages = {
    archiveAndHash ? false,
    cargoLock,
    cargoToml,
    extraArgs ? {},
    fenix,
    installData,
    linuxVariant ? "musl",
    nixpkgs,
    overlays,
    pkgs,
    src,
    system,
    systems,
  }: let
    utils = import ../utils.nix;
    crossPkgs = target: let
      fenixTarget = utils.getTarget {
        system = target;
        variant = linuxVariant;
      };
      isTargetLinux = builtins.match ".*-linux" target != null;
      tmpPkgs = import nixpkgs {
        inherit overlays system;
        crossSystem = {
          config = fenixTarget;
          isStatic = isTargetLinux;
          rustc = {config = fenixTarget;};
        };
      };
      toolchain = with fenix.packages.${system};
        combine [
          stable.cargo
          stable.rustc
          targets.${fenixTarget}.stable.rust-std
        ];
      callPackage = tmpPkgs.lib.callPackageWith (tmpPkgs
        // {
          config = fenixTarget;
          toolchain = toolchain;
        });
    in {
      inherit callPackage;
      pkgs = tmpPkgs;
      toolchain = toolchain;
    };

    systemPackages = builtins.listToAttrs (map (target: {
        name = target;
        value = let
          cross = crossPkgs target;
          plain = cross.callPackage ./build.nix {
            inherit cargoToml cargoLock src extraArgs;
            toolchain = cross.toolchain;
          };
          archiveAndHashLib = import ../archiveAndHash.nix;
        in
          if archiveAndHash
          then
            archiveAndHashLib {
              pkgs = cross.pkgs;
              drv = plain;
              name = cargoToml.package.name;
            }
          else plain;
      })
      systems);

    defaultPackage = pkgs.callPackage ./install.nix {
      inherit cargoToml;
      data = installData.${system};
    };
  in
    systemPackages // {default = defaultPackage;};
in {
  inherit buildPackages;
}
