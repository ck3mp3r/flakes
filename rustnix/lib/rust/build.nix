{
  cargoLock,
  cargoToml,
  extraArgs ? {},
  workspaceMember ? null,
  pkgs,
  src,
  toolchain,
}: let
  pname =
    if workspaceMember != null
    then workspaceMember
    else cargoToml.package.name;
  version =
    if cargoToml ? package
    then cargoToml.package.version
    else cargoToml.workspace.package.version;
  cargoBuildFlags =
    if workspaceMember != null
    then ["-p" workspaceMember]
    else [];

  drv =
    (pkgs.makeRustPlatform {
      cargo = toolchain;
      rustc = toolchain;
    }).buildRustPackage ({
        inherit
          pname
          version
          src
          cargoLock
          cargoBuildFlags
          ;
        buildInputs = extraArgs.buildInputs or [];
        nativeBuildInputs = extraArgs.nativeBuildInputs or [];

        postFixup = pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
          for bin in $out/bin/*; do
            if [[ -f "$bin" && -x "$bin" ]]; then
              # Replace Nix store paths with system paths for common libraries
              ${pkgs.stdenv.cc.targetPrefix}install_name_tool -change \
                "${pkgs.libiconv}/lib/libiconv.2.dylib" \
                "/usr/lib/libiconv.2.dylib" \
                "$bin" 2>/dev/null || true
            fi
          done
        '';
      }
      // extraArgs);
in
  drv
