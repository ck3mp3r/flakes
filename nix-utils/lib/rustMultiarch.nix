{
  archiveAndHash ? false,
  cargoLock,
  cargoToml,
  extraArgs ? {},
  fenix,
  nixpkgs,
  overlays ? [],
  src,
  systems ? [
    "aarch64-darwin"
    "x86_64-darwin"
    "aarch64-linux"
    "x86_64-linux"
  ],
}: let
  archiveAndHashLib =
    if archiveAndHash
    then import ./archiveAndHash.nix
    else null;

  cargo = builtins.fromTOML (builtins.readFile cargoToml);
  pname = cargo.package.name;
  version = cargo.package.version;

  mkRustPkg = {
    buildSystem,
    targetSystem,
  }: let
    pkgs = import nixpkgs {
      system = buildSystem;
      overlays = overlays;
      crossSystem =
        if buildSystem != targetSystem
        then {config = targetSystem;}
        else null;
    };
    fenixToolchain = fenix.packages.${targetSystem}.stable.toolchain;
    # Add rust-std for cross targets
    rustStd =
      if buildSystem != targetSystem
      then fenix.packages.${buildSystem}.targets.${targetSystem}.stable.rust-std
      else null;
    rustPlatform = pkgs.makeRustPlatform {
      cargo = fenixToolchain;
      rustc = fenixToolchain;
      rust-analyzer = fenixToolchain;
    };
    drv = rustPlatform.buildRustPackage ({
        inherit pname version src cargoLock;
        buildInputs =
          (extraArgs.buildInputs or [])
          ++ (
            if rustStd != null
            then [rustStd]
            else []
          );
      }
      // extraArgs);
    wrapped =
      if archiveAndHashLib != null
      then
        archiveAndHashLib {
          inherit pkgs drv;
          name = pname;
          compress = true;
        }
      else drv;
  in
    wrapped;

  perHost = host: let
    native = mkRustPkg {
      buildSystem = host;
      targetSystem = host;
    };
    cross = builtins.listToAttrs (
      builtins.filter (x: x != null) (
        map (
          target:
            if target != host
            then {
              name = target;
              value = mkRustPkg {
                buildSystem = host;
                targetSystem = target;
              };
            }
            else null
        )
        systems
      )
    );
  in
    {
      default = native;
      ${host} = native;
    }
    // cross;
in
  builtins.listToAttrs (map (host: {
      name = host;
      value = perHost host;
    })
    systems)
