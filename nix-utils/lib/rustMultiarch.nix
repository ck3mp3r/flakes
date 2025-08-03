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

  rustTargetForSystem = system:
    {
      "aarch64-linux" = "aarch64-unknown-linux-gnu";
      "x86_64-linux" = "x86_64-unknown-linux-gnu";
      "aarch64-darwin" = "aarch64-apple-darwin";
      "x86_64-darwin" = "x86_64-apple-darwin";
    }.${
      system
    } or (throw "No Rust target triple for system: ${system}");

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
    fenixPkgs = fenix.packages.${buildSystem};
    rustTarget = rustTargetForSystem targetSystem;
    toolchain = fenixPkgs.combine (
      [fenixPkgs.stable.cargo fenixPkgs.stable.rustc]
      ++ (
        if buildSystem != targetSystem
        then [fenixPkgs.targets.${rustTarget}.stable.rust-std]
        else []
      )
    );
    rustPlatform = pkgs.makeRustPlatform {
      cargo = toolchain;
      rustc = toolchain;
    };
    drv = rustPlatform.buildRustPackage ({
        inherit pname version src cargoLock;
        buildInputs = extraArgs.buildInputs or [];
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
