{
  cargoLock,
  cargoToml,
  extraArgs ? {},
  pkgs,
  src,
  toolchain,
}: let
  pname = cargoToml.package.name;
  inherit (cargoToml.package) version;

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
