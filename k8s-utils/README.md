# Kubernetes Utilities Flake

This flake provides a comprehensive bundle of Kubernetes CLI tools and utilities for development, operations, and management tasks.

## What's Included

This flake bundles the following Kubernetes-related applications:

### Core Tools
- **kubectl** - The main Kubernetes command-line tool
- **kubectx** - Fast way to switch between Kubernetes clusters
- **kustomize** - Kubernetes configuration management tool
- **helm** (kubernetes-helm) - The Kubernetes package manager

### Development & Testing
- **kind** - Kubernetes in Docker - local Kubernetes clusters
- **tilt** - A toolkit for fixing the pains of microservice development
- **colima** - Container runtime for macOS (Darwin only)

### Monitoring & Debugging
- **k9s** - Terminal-based UI for Kubernetes clusters
- **stern** - Multi-pod and container log tailing

## Usage

### Quick Run (Ephemeral Shell)

For temporary use without installing, you can enter an ephemeral shell with all tools available:

```bash
# Enter a shell with all k8s tools available
nix shell github:ck3mp3r/flakes?dir=k8s-utils

# Or use the shorter syntax
nix shell github:ck3mp3r/flakes#k8s-utils
```

This gives you immediate access to all bundled tools without modifying your system. When you exit the shell, the tools are no longer available.

### Install the entire bundle

```bash
# Install all tools permanently
nix profile install github:ck3mp3r/flakes?dir=k8s-utils
```

### Use in your own flake

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    k8s-utils.url = "github:ck3mp3r/flakes?kubernetes";
  };

  outputs = { self, nixpkgs, k8s-utils, ... }: {
    # Use the overlay
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [ k8s-utils.overlays.default ];
    };
    
    # Or reference the package directly
    devShells.default = nixpkgs.mkShell {
      buildInputs = [ k8s-utils.packages.x86_64-linux.default ];
    };
  };
}
```

## Platform Support

- **Linux** (x86_64, aarch64)
- **macOS** (x86_64, aarch64) - includes macOS-specific tools like colima

## Quick Start

Once installed, you'll have access to all the bundled tools. Here are some common workflows:

```bash
# Switch between clusters
kubectx my-cluster

# Switch between namespaces
kubens my-namespace

# Monitor your cluster with a TUI
k9s

# View logs from multiple pods
stern my-app

# Deploy with Helm
helm install my-release ./my-chart

# Apply Kustomize configurations
kustomize build ./overlays/production | kubectl apply -f -
```

## Contributing

This flake is part of the [ck3mp3r/flakes](https://github.com/ck3mp3r/flakes) repository. Please see the main repository for contribution guidelines.

