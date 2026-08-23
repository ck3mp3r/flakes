{fenix}: let
  utils = import ../utils.nix;

  mkPkgs = {
    system,
    nixpkgs,
    overlays ? [],
    config ? {},
    crossSystem ? null,
  }:
    import nixpkgs ({
        inherit system overlays;
        config = {allowUnfree = true;} // config;
      }
      // (
        if crossSystem != null
        then {inherit crossSystem;}
        else {}
      ));

  # fenix bug: on Darwin, rust-objcopy/rust-lld load `@rpath/libLLVM.dylib`
  # relative to `@loader_path/../lib`, i.e. `$lib/rustlib/<triplet>/lib`, but the
  # dylib only ships at `$out/lib/libLLVM.dylib`. The fenix `combine` (symlinkJoin)
  # only materializes `$out/bin` and `librustc_driver-*`, so this must be fixed in
  # the rustc component itself (rustc-unwrapped) before toolchain assembly.
  rustcFor = system: let
    p = fenix.packages.${system};
    isDarwin = builtins.match ".*-darwin" system != null;
    rustc =
      if isDarwin
      then p.stable.rustc-unwrapped
      else p.stable.rustc;
  in
    if !isDarwin
    then rustc
    else
      rustc.overrideAttrs (old: {
        installPhase =
          (old.installPhase or "")
          + ''
            if [ -d "$out/lib" ] && [ -e "$out/lib/libLLVM.dylib" ]; then
              for tgt in "$out"/lib/rustlib/*; do
                if [ -d "$tgt" ] && [ -e "$tgt/bin/rust-objcopy" ]; then
                  mkdir -p "$tgt/lib"
                  if [ ! -e "$tgt/lib/libLLVM.dylib" ]; then
                    ln -s "$out/lib/libLLVM.dylib" "$tgt/lib/libLLVM.dylib"
                  fi
                fi
              done
            fi
          '';
      });

  mkToolchain = {
    system,
    targets ? [],
    extras ? [],
    variant ? "musl",
  }: let
    fenixTarget = utils.getTarget {inherit system variant;};
    baseToolchain = [
      fenix.packages.${system}.stable.cargo
      (rustcFor system)
      fenix.packages.${system}.targets.${fenixTarget}.stable.rust-std
    ];
    additionalStd = map (t: fenix.packages.${system}.targets.${t}.stable.rust-std) targets;
    extraComponents = map (e: fenix.packages.${system}.stable.${e}) extras;
  in
    fenix.packages.${system}.combine (baseToolchain ++ additionalStd ++ extraComponents);

  mkRustPlatform = {
    system,
    nixpkgs,
    overlays ? [],
    targets ? [],
    extras ? [],
    variant ? "musl",
    config ? {},
  }: let
    pkgs = mkPkgs {inherit system nixpkgs overlays config;};
    toolchain = mkToolchain {inherit system targets extras variant;};
  in
    pkgs.makeRustPlatform {
      cargo = toolchain;
      rustc = toolchain;
    };

  # Configure cross-compilation pkgs for a specific target
  mkCrossPkgs = {
    system,
    target,
    nixpkgs,
    overlays,
    additionalTargets ? [],
    linuxVariant ? "musl",
  }: let
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
        mkPkgs {
          inherit system nixpkgs overlays;
          crossSystem = {
            config = fenixTarget;
            rustc = {config = fenixTarget;};
            isStatic = isTargetLinux; # Static musl builds for Linux
          };
        }
      else mkPkgs {inherit system nixpkgs overlays;};

    # Toolchain always comes from build system
    toolchain = with fenix.packages.${system};
      combine (
        [
          stable.cargo
          (rustcFor system)
          targets.${fenixTarget}.stable.rust-std # Target-specific stdlib
        ]
        ++ (map (t: targets.${t}.stable.rust-std) additionalTargets)
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

  # Assemble the final package attribute set from components
  mkPackageSet = {
    defaultPackage,
    mainPackage,
    packageName ? null,
    aliases ? [],
  }: let
    basePackages = {default = defaultPackage;};
    namedPackage =
      if packageName != null
      then {${packageName} = mainPackage;}
      else {};
    aliasPackages = builtins.listToAttrs (map (alias: {
        name = alias;
        value = mainPackage;
      })
      aliases);
  in
    basePackages // namedPackage // aliasPackages;

  buildTargetOutputs = {
    archiveAndHash ? false,
    buildInputs ? [],
    cargoLock,
    cargoToml,
    extraArgs ? {},
    installData,
    linuxVariant ? "musl",
    nativeBuildInputs ? [],
    nixpkgs,
    overlays,
    packageName ? null,
    workspaceMember ? null,
    pkgs,
    src,
    system,
    supportedTargets,
    aliases ? [],
    additionalTargets ? [],
  }:
    if !(builtins.elem system supportedTargets)
    then {}
    else let
      cross = mkCrossPkgs {
        inherit system nixpkgs overlays additionalTargets linuxVariant;
        target = system;
      };

      mergedExtraArgs =
        extraArgs
        // {
          buildInputs = (extraArgs.buildInputs or []) ++ buildInputs;
          nativeBuildInputs = (extraArgs.nativeBuildInputs or []) ++ nativeBuildInputs;
        };

      binaryPackage = cross.callPackage ./build.nix {
        inherit cargoToml cargoLock src workspaceMember;
        extraArgs = mergedExtraArgs;
        inherit (cross) toolchain;
      };

      archiveAndHashLib = import ../archiveAndHash.nix;
      distributionBundle = archiveAndHashLib {
        inherit pkgs;
        drv = binaryPackage;
        name =
          if workspaceMember != null
          then workspaceMember
          else cargoToml.package.name;
      };

      mainPackage =
        if archiveAndHash
        then distributionBundle
        else binaryPackage;

      defaultPackage =
        if installData != null && installData ? ${system}
        then
          pkgs.callPackage ./install.nix {
            inherit cargoToml workspaceMember;
            data = installData.${system};
          }
        else mainPackage;
    in
      mkPackageSet {
        inherit defaultPackage mainPackage packageName aliases;
      };
in {
  inherit buildTargetOutputs mkCrossPkgs mkPackageSet mkPkgs mkToolchain mkRustPlatform;
  overlays.fenix = fenix.overlays.default;
}
