let
  buildPackage = {
    archiveAndHash ? false,
    buildInputs ? [],
    cargoLock,
    cargoToml,
    extraArgs ? {},
    fenix,
    installData ? null,
    linuxVariant ? "musl",
    nativeBuildInputs ? [],
    nixpkgs,
    overlays,
    packageName ? null,
    pkgs,
    src,
    system,
    targetSystem ? system,
    aliases ? [],
  }: let
    utils = import ../utils.nix;
    
    # Build for the target system
    fenixTarget = utils.getTarget {
      system = targetSystem;
      variant = linuxVariant;
    };
    isTargetLinux = builtins.match ".*-linux" targetSystem != null;
    isCrossCompiling = targetSystem != system;

    tmpPkgs =
      if isCrossCompiling || isTargetLinux
      then import nixpkgs {
        inherit overlays system;
        crossSystem = {
          config = fenixTarget;
          rustc = {config = fenixTarget;};
          isStatic = isTargetLinux;
        };
      }
      else import nixpkgs {inherit overlays system;};
      
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

    mergedExtraArgs =
      extraArgs
      // {
        buildInputs = (extraArgs.buildInputs or []) ++ buildInputs;
        nativeBuildInputs = (extraArgs.nativeBuildInputs or []) ++ nativeBuildInputs;
      };
      
    # Build the plain package
    plainPackage = callPackage ./build.nix {
      inherit cargoToml cargoLock src;
      extraArgs = mergedExtraArgs;
      toolchain = toolchain;
    };
    
    # Create archive if requested
    archiveAndHashLib = import ../archiveAndHash.nix;
    archivedPackage = archiveAndHashLib {
      inherit pkgs;
      drv = plainPackage;
      name = "${cargoToml.package.name}-${targetSystem}";
    };
    
    # Default package (pre-built installer)
    defaultPackage = 
      if installData != null && installData ? ${system}
      then pkgs.callPackage ./install.nix {
        inherit cargoToml;
        data = installData.${system};
      }
      else plainPackage;

    # Main package result
    mainPackage = if archiveAndHash then archivedPackage else plainPackage;
    
    # Create base packages
    basePackages = { default = defaultPackage; };
    
    # Add main package with custom name if provided
    namedPackage =
      if packageName != null
      then {${packageName} = mainPackage;}
      else {};

    # Add aliases (all point to main package)
    aliasPackages = builtins.listToAttrs (map (alias: {
        name = alias;
        value = mainPackage;
      })
      aliases);
  in
    basePackages // namedPackage // aliasPackages;
in {
  inherit buildPackage;
  # Keep backward compatibility
  buildPackages = buildPackage;
}
