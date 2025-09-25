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
  in let
    basePackages = systemPackages // {default = defaultPackage;};

    # Add main package with custom name if provided
    namedPackage =
      if packageName != null
      then {${packageName} = systemPackages.${system};} # Points to current system build
      else {};

    # Add aliases (all point to current system build)
    aliasPackages = builtins.listToAttrs (map (alias: {
        name = alias;
        value = systemPackages.${system};
      })
      aliases);
  in
    basePackages // namedPackage // aliasPackages;
in {
  inherit buildPackages;
}
