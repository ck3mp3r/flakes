{
  cargoToml,
  data,
  pkgs,
}:
pkgs.stdenvNoCC.mkDerivation rec {
  pname = cargoToml.package.name;
  version = cargoToml.package.version;

  src = pkgs.fetchurl {
    url = data.url;
    sha256 = data.hash;
  };

  phases = ["unpackPhase" "installPhase"];

  unpackPhase = ''
    tar -xzf ${src}
  '';

  installPhase = ''
    mkdir -p $out/bin
    ls
    cp bin/${cargoToml.package.name} $out/bin/${cargoToml.package.name}
    chmod +x $out/bin/${cargoToml.package.name}
  '';
}
