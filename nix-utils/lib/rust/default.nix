let
  buildPackages = {
    archiveAndHash ? false,
    cargoLock,
    cargoToml,
    extraArgs ? {},
    fenix,
    installData,
    nixpkgs,
    overlays,
    pkgs,
    src,
    system,
    systems,
    linuxVariant ? "musl",
  }: let
    utils = import ../utils.nix;
    crossPkgs = target: let
      isCrossCompiling = target != system;
      fenixTarget = utils.getTarget {
        system = target;
        variant = linuxVariant;
      };
      tmpPkgs = import nixpkgs {
        inherit overlays system;
        crossSystem =
          if isCrossCompiling || pkgs.stdenv.isLinux
          then {
            config = fenixTarget;
            rustc = {config = fenixTarget;};
            isStatic = pkgs.stdenv.isLinux;
          }
          else null;
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
