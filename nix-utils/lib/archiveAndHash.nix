{
  pkgs,
  drv,
  name ? "artifact",
  compress ? true,
}: let
  artifact =
    if compress
    then
      pkgs.runCommand "${name}.tgz" {buildInputs = [pkgs.gnutar pkgs.gzip];} ''
        tar czf $out -C ${drv} .
      ''
    else drv;

  nixHash = pkgs.runCommand "${name}-nix.sha256" {buildInputs = [pkgs.nix];} ''
    nix-hash --type sha256 --flat --base32 ${artifact} > $out
  '';

  sha256 = pkgs.runCommand "${name}.sha256" {buildInputs = [pkgs.coreutils];} ''
    sha256sum ${artifact} | cut -f1 -d' ' > $out
  '';
in
  artifact
  // {
    inherit nixHash sha256;
    pname = drv.pname or name;
    version = drv.version or "unknown";
    meta = drv.meta or {};
  }
