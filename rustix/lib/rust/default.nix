let
  buildPackages = {
    archiveAndHash ? false,
    buildInputs ? [],
    cargoLock,
    cargoToml,
    extraArgs ? {},
    fenix,
    installData,
    linuxVariant ? "musl",
    nativeBuildInputs ? [],
    nixpkgs,
    overlays,
    packageName ? null,
    pkgs,
    src,
    system,
    systems,
    aliases ? [],
  }: let
    utils = import ../utils.nix;
    crossPkgs = target: let
      fenixTarget = utils.getTarget {
        system = target;
        variant = linuxVariant;
      };
      isTargetLinux = builtins.match ".*-linux" target != null;
      isCrossCompiling = target != system;

      tmpPkgs = import nixpkgs {
        inherit overlays system;
        crossSystem =
          if isCrossCompiling || isTargetLinux
          then {
            config = fenixTarget;
            rustc = {config = fenixTarget;};
            isStatic = isTargetLinux;
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
          mergedExtraArgs =
            extraArgs
            // {
              buildInputs = (extraArgs.buildInputs or []) ++ buildInputs;
              nativeBuildInputs = (extraArgs.nativeBuildInputs or []) ++ nativeBuildInputs;
            };
          plain = cross.callPackage ./build.nix {
            inherit cargoToml cargoLock src;
            extraArgs = mergedExtraArgs;
            toolchain = cross.toolchain;
          };
          archiveAndHashLib = import ../archiveAndHash.nix;
          archived = archiveAndHashLib {
            inherit pkgs;
            drv = plain;
            name = cargoToml.package.name;
          };
        in
          if archiveAndHash
          then archived
          else plain;
      })
      systems);

    # Create separate plain builds for installable packages
    plainSystemPackages = builtins.listToAttrs (map (target: {
        name = target;
        value = let
          cross = crossPkgs target;
          mergedExtraArgs =
            extraArgs
            // {
              buildInputs = (extraArgs.buildInputs or []) ++ buildInputs;
              nativeBuildInputs = (extraArgs.nativeBuildInputs or []) ++ nativeBuildInputs;
            };
        in
          cross.callPackage ./build.nix {
            inherit cargoToml cargoLock src;
            extraArgs = mergedExtraArgs;
            toolchain = cross.toolchain;
          };
      })
      systems);

    defaultPackage = pkgs.callPackage ./install.nix {
      inherit cargoToml;
      data = installData.${system};
    };
  in let
    basePackages = systemPackages // {default = defaultPackage;};

    # Add main package with custom name if provided (always installable)
    namedPackage =
      if packageName != null
      then {${packageName} = plainSystemPackages.${system};} # Points to plain current system build
      else {};

    # Add aliases (all point to plain current system build for installability)
    aliasPackages = builtins.listToAttrs (map (alias: {
        name = alias;
        value = plainSystemPackages.${system};
      })
      aliases);
  in
    basePackages // namedPackage // aliasPackages;
in {
  inherit buildPackages;
}
