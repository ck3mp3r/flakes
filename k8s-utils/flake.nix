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

        # Bundle of Kubernetes-related applications
        k8s-bundle = pkgs.buildEnv {
          name = "k8s-utils";
          paths = with pkgs;
            [
              argocd
              k9s
              kind
              kubectl
              kubectx
              kubernetes-helm
              kustomize
              stern
              tilt
            ]
            ++ lib.optionals stdenv.isDarwin [colima];
          pathsToLink = ["/bin" "/share"];
        };
      in {
        formatter = pkgs.alejandra;
        packages.default = k8s-bundle;
      }
    )
    // {
      overlays.default = final: prev: {
        k8s-utils = self.packages.${final.system}.default;
      };
    };
}
