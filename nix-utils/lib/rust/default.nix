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
      isNative = target == system;

      tmpPkgs =
        if isNative && isTargetLinux
        then (import nixpkgs {inherit overlays system;}).pkgsStatic
        else
          import nixpkgs {
            inherit overlays system;
            crossSystem =
              if isNative
              then null
              else
                {
                  config = fenixTarget;
                  rustc = {config = fenixTarget;};
                }
                // (
                  if isTargetLinux
                  then {isStatic = true;}
                  else {}
                );
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
              inherit pkgs;
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
