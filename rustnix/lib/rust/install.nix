{
  cargoToml,
  data,
  pkgs,
}:
pkgs.stdenvNoCC.mkDerivation rec {
  pname = cargoToml.package.name;
  inherit (cargoToml.package) version;

  src = pkgs.fetchurl {
    inherit (data) url;
    sha256 = data.hash;
  };

  phases = ["unpackPhase" "installPhase"];

  unpackPhase = ''
    tar -xzf ${src}
  '';

  installPhase = ''
    mkdir -p $out/bin
    ls -la bin/
    for file in bin/*; do
      if [ -f "$file" ]; then
        if file "$file" | grep -q "executable"; then
          cp "$file" $out/bin/
          chmod +x $out/bin/$(basename "$file")
        fi
      fi
    done
  '';
}
