{
  description = "This brings in clis and utilities related to kubernetes.";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config = {allowUnfree = true;};
        };

        # Kubernetes MCP tools for nushell
        k8s-mcp-tools = pkgs.stdenv.mkDerivation {
          name = "k8s-mcp-tools";
          version = "0.1.0";
          src = ./mcp-tools;

          buildInputs = with pkgs; [nushell];

          installPhase = ''
            mkdir -p $out/share/nushell/mcp-tools/k8s
            cp -r * $out/share/nushell/mcp-tools/k8s/

            # Make all .nu files executable
            find $out/share/nushell/mcp-tools/k8s -name "*.nu" -exec chmod +x {} \;
          '';

          meta = with pkgs.lib; {
            description = "Kubernetes MCP tools for nushell providing LLM-safe kubectl functionality";
            homepage = "https://github.com/ck3mp3r/flakes";
            license = licenses.mit;
            maintainers = [];
            platforms = platforms.all;
          };
        };

        # Bundle of Kubernetes-related applications
        k8s-bundle = pkgs.buildEnv {
          name = "k8s-utils";
          paths = with pkgs;
            [
              k9s
              kind
              kubectl
              kubectx
              kubernetes-helm
              kustomize
              stern
              tilt
              k8s-mcp-tools
            ]
            ++ lib.optionals stdenv.isDarwin [colima];
          pathsToLink = ["/bin" "/share"];
        };
      in {
        formatter = pkgs.alejandra;
        packages = {
          default = k8s-bundle;
          k8s-mcp-tools = k8s-mcp-tools;
        };
      }
    )
    // {
      overlays.default = final: prev: {
        k8s-utils = self.packages.${final.system}.default;
      };
    };
}
