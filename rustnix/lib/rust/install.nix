{
  cargoToml,
  data,
  workspaceMember ? null,
  pkgs,
}:
pkgs.stdenvNoCC.mkDerivation rec {
  pname =
    if workspaceMember != null
    then workspaceMember
    else cargoToml.package.name;
  version =
    if cargoToml ? package
    then cargoToml.package.version
    else cargoToml.workspace.package.version;

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
