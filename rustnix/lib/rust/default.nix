let
  buildTargetOutputs = {
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
    system, # Build system (your machine)
    supportedTargets, # List of target architectures to support
    aliases ? [],
  }: let
    utils = import ../utils.nix;

    # Check if current system is supported
    isSystemSupported = builtins.elem system supportedTargets;

    # Configure cross-compilation for a specific target
    crossPkgs = target: let
      fenixTarget = utils.getTarget {
        system = target;
        variant = linuxVariant;
      };
      isTargetLinux = builtins.match ".*-linux" target != null;
      isCrossCompiling = target != system;

      # Import nixpkgs with cross-compilation support when needed
      tmpPkgs =
        if isCrossCompiling || isTargetLinux
        then
          import nixpkgs {
            inherit overlays system; # Build on 'system'
            crossSystem = {
              config = fenixTarget;
              rustc = {config = fenixTarget;};
              isStatic = isTargetLinux; # Static musl builds for Linux
            };
          }
        else import nixpkgs {inherit overlays system;};

      # Toolchain always comes from build system
      toolchain = with fenix.packages.${system};
        combine (
          [
            stable.cargo
            stable.rustc
            targets.${fenixTarget}.stable.rust-std # Target-specific stdlib
          ]
          ++ (map (target: targets.${target}.stable.rust-std) additionalTargets)
        );
      callPackage = tmpPkgs.lib.callPackageWith (tmpPkgs
        // {
          config = fenixTarget;
          inherit toolchain;
        });
    in {
      inherit callPackage;
      pkgs = tmpPkgs;
      inherit toolchain;
    };
  in
    # Only build package if current system is supported
    if !isSystemSupported
    then {}
    else let
      # Build package for current system only
      cross = crossPkgs system;
      mergedExtraArgs =
        extraArgs
        // {
          buildInputs = (extraArgs.buildInputs or []) ++ buildInputs;
          nativeBuildInputs = (extraArgs.nativeBuildInputs or []) ++ nativeBuildInputs;
        };

      # Build binary package
      binaryPackage = cross.callPackage ./build.nix {
        inherit cargoToml cargoLock src;
        extraArgs = mergedExtraArgs;
        inherit (cross) toolchain;
      };

      # Create distribution bundle if requested
      archiveAndHashLib = import ../archiveAndHash.nix;
      distributionBundle = archiveAndHashLib {
        inherit pkgs;
        drv = binaryPackage;
        inherit (cargoToml.package) name;
      };

      # Choose main package based on archiveAndHash flag
      mainPackage =
        if archiveAndHash
        then distributionBundle
        else binaryPackage;

      # Pre-built installer from installData (if available)
      defaultPackage =
        if installData != null && installData ? ${system}
        then
          pkgs.callPackage ./install.nix {
            inherit cargoToml;
            data = installData.${system};
          }
        else mainPackage;

      # Create base packages
      basePackages = {default = defaultPackage;};

      # Add main package with custom name (respects archiveAndHash flag)
      namedPackage =
        if packageName != null
        then {${packageName} = mainPackage;}
        else {};

      # Add aliases pointing to main package (respects archiveAndHash flag)
      aliasPackages = builtins.listToAttrs (map (alias: {
          name = alias;
          value = mainPackage;
        })
        aliases);
    in
      basePackages // namedPackage // aliasPackages;
in {
  inherit buildTargetOutputs;
}
