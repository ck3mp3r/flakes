{
  pkgs,
  drv,
  name ? "artifact",
  compress ? true,
}: let
  tgz =
    if compress
    then
      pkgs.runCommand "${name}.tgz" {buildInputs = [pkgs.gnutar pkgs.gzip];} ''
        tar czf $out -C ${drv} .
      ''
    else drv;

  nixHash = pkgs.runCommand "${name}-nix.sha256" {buildInputs = [pkgs.nix];} ''
    nix-hash --type sha256 --flat --base32 ${tgz} > $out
  '';

  sha256 = pkgs.runCommand "${name}.sha256" {buildInputs = [pkgs.coreutils];} ''
    sha256sum ${tgz} | cut -f1 -d' ' > $out
  '';
in
  pkgs.runCommand "${name}-bundle" {} ''
    mkdir -p $out
    install -m644 ${tgz} $out/${name}.tgz
    install -m644 ${nixHash} $out/${name}-nix.sha256
    install -m644 ${sha256} $out/${name}.sha256
  ''
