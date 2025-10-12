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
    system, # Build system (your machine)
    targets, # List of target architectures to support
    aliases ? [],
  }: let
    utils = import ../utils.nix;

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
        combine [
          stable.cargo
          stable.rustc
          targets.${fenixTarget}.stable.rust-std # Target-specific stdlib
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

    # Package outputs for each target architecture
    packageOutputs = builtins.listToAttrs (map (target: {
        name = target;
        value = let
          cross = crossPkgs target;
          mergedExtraArgs =
            extraArgs
            // {
              buildInputs = (extraArgs.buildInputs or []) ++ buildInputs;
              nativeBuildInputs = (extraArgs.nativeBuildInputs or []) ++ nativeBuildInputs;
            };
          binaryPackage = cross.callPackage ./build.nix {
            inherit cargoToml cargoLock src;
            extraArgs = mergedExtraArgs;
            toolchain = cross.toolchain;
          };
          archiveAndHashLib = import ../archiveAndHash.nix;
          distributionBundle = archiveAndHashLib {
            inherit pkgs;
            drv = binaryPackage;
            name = cargoToml.package.name;
          };
        in
          if archiveAndHash
          then distributionBundle # .tgz with hashes for distribution
          else binaryPackage; # Just the binary executable
      })
      targets);

    # Binary package outputs for installable packages
    binaryOutputs = builtins.listToAttrs (map (target: {
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
      targets);

    # Pre-built installer from installData
    defaultPackage = pkgs.callPackage ./install.nix {
      inherit cargoToml;
      data = installData.${system};
    };
  in let
    basePackages = packageOutputs // {default = defaultPackage;};

    # Add main package with custom name (installable binary)
    namedPackage =
      if packageName != null
      then {${packageName} = binaryOutputs.${system};}
      else {};

    # Add aliases pointing to current system binary
    aliasPackages = builtins.listToAttrs (map (alias: {
        name = alias;
        value = binaryOutputs.${system};
      })
      aliases);
  in
    basePackages // namedPackage // aliasPackages;
in {
  inherit buildPackages;
}
