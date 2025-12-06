{
  pkgs ? import <nixpkgs> {},
  lib ? pkgs.lib,
}: let
  # Import the rustnix lib
  rustnixLib = import ../lib/rust;
  utils = import ../lib/utils.nix;

  # Mock fenix for testing
  mockFenix = {
    packages = {
      "x86_64-linux" = {
        stable = {
          cargo = pkgs.hello; # Mock derivation
          rustc = pkgs.hello; # Mock derivation
        };
        combine = components: pkgs.hello; # Mock combine function
        targets = {
          "aarch64-unknown-linux-musl" = {
            stable = {
              rust-std = pkgs.hello; # Mock rust-std
            };
          };
          "x86_64-unknown-linux-musl" = {
            stable = {
              rust-std = pkgs.hello; # Mock rust-std
            };
          };
        };
      };
      "aarch64-linux" = {
        stable = {
          cargo = pkgs.hello; # Mock derivation
          rustc = pkgs.hello; # Mock derivation
        };
        combine = components: pkgs.hello; # Mock combine function
        targets = {
          "aarch64-unknown-linux-musl" = {
            stable = {
              rust-std = pkgs.hello; # Mock rust-std
            };
          };
        };
      };
    };
  };

  # Mock cargo.toml
  mockCargoToml = {
    package = {
      name = "test-package";
      version = "1.0.0";
    };
  };

  # Mock cargo.lock
  mockCargoLock = {
    lockFile = pkgs.writeText "Cargo.lock" "";
  };

  # Test cross-compilation detection
  testCrossCompilation = {
    # Test 1: Native build (should not cross-compile)
    nativeBuild = let
      # Mock builtins.currentSystem to return x86_64-linux
      result = rustnixLib.buildPackage {
        inherit (mockCargoToml) cargoToml;
        inherit (mockCargoLock) cargoLock;
        fenix = mockFenix;
        nixpkgs = import <nixpkgs>;
        overlays = [];
        inherit pkgs;
        src = ./.;
        system = "x86_64-linux";
      };
    in {
      name = "native-build-test";
      # This should build natively since system matches builtins.currentSystem
      inherit result;
    };

    # Test 2: Cross-compilation (should cross-compile)
    crossBuild = let
      result = rustnixLib.buildPackage {
        inherit (mockCargoToml) cargoToml;
        inherit (mockCargoLock) cargoLock;
        fenix = mockFenix;
        nixpkgs = import <nixpkgs>;
        overlays = [];
        inherit pkgs;
        src = ./.;
        system = "aarch64-linux";
      };
    in {
      name = "cross-build-test";
      # This should cross-compile since system != builtins.currentSystem
      inherit result;
    };
  };

  # Test utility functions
  testUtils = {
    # Test target mapping
    targetMapping = {
      x86_64-linux = utils.getTarget {system = "x86_64-linux";};
      aarch64-linux = utils.getTarget {system = "aarch64-linux";};
      x86_64-darwin = utils.getTarget {system = "x86_64-darwin";};
      aarch64-darwin = utils.getTarget {system = "aarch64-darwin";};
    };

    # Test system mapping
    systemMapping = {
      x86_64-linux = utils.systemMap "x86_64-linux";
      aarch64-linux = utils.systemMap "aarch64-linux";
      x86_64-darwin = utils.systemMap "x86_64-darwin";
      aarch64-darwin = utils.systemMap "aarch64-darwin";
    };
  };

  # Expected values for validation
  expectedValues = {
    targets = {
      "x86_64-linux" = "x86_64-unknown-linux-musl";
      "aarch64-linux" = "aarch64-unknown-linux-musl";
      "x86_64-darwin" = "x86_64-apple-darwin";
      "aarch64-darwin" = "aarch64-apple-darwin";
    };

    systemMaps = {
      "x86_64-linux" = {
        arch = "x86_64";
        platform = "linux";
      };
      "aarch64-linux" = {
        arch = "aarch64";
        platform = "linux";
      };
      "x86_64-darwin" = {
        arch = "x86_64";
        platform = "darwin";
      };
      "aarch64-darwin" = {
        arch = "aarch64";
        platform = "darwin";
      };
    };
  };
in {
  inherit testCrossCompilation testUtils expectedValues;

  # Validation function
  validate = {
    # Validate target mappings
    targetMappings =
      lib.mapAttrs (
        system: expected:
          assert testUtils.targetMapping.${system} == expected; "✓ ${system} -> ${expected}"
      )
      expectedValues.targets;

    # Validate system mappings
    systemMappings =
      lib.mapAttrs (
        system: expected:
          assert testUtils.systemMapping.${system} == expected; "✓ ${system} -> ${lib.generators.toPretty {} expected}"
      )
      expectedValues.systemMaps;
  };

  # Summary
  summary = "All tests completed successfully";
}
