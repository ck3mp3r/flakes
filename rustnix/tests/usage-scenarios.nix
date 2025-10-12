# Test the correct usage scenarios with rustnix multi-system approach
{
  pkgs ? import <nixpkgs> {},
  lib ? pkgs.lib,
}: let
  # Test how users should properly use rustnix for cross-compilation
  # The correct approach is to use .#packages.target-system.package
  # Mock rustnix lib usage
  mockRustnixUsage = {
    buildSystem,
    targets,
    cargoToml,
  }: let
    utils = import ../lib/utils.nix;

    # This simulates how buildTargetOutputs works for each target
    buildForTarget = target: let
      fenixTarget = utils.getTarget {
        system = target;
        variant = "musl";
      };
      isTargetLinux = builtins.match ".*-linux" target != null;
      isCrossCompiling = target != buildSystem;

      nixpkgsConfig = {
        system = buildSystem; # Always use build system
        crossSystem = lib.optionalAttrs (isCrossCompiling || isTargetLinux) {
          config = fenixTarget;
          rustc = {config = fenixTarget;};
          isStatic = isTargetLinux;
        };
      };
    in {
      inherit target buildSystem fenixTarget isCrossCompiling;
      inherit nixpkgsConfig;
      packageName = "${cargoToml.package.name}-${target}";
      toolchainFrom = buildSystem;
    };

    # Build packages for all target systems
    packages = builtins.listToAttrs (map (target: {
        name = target;
        value = buildForTarget target;
      })
      targets);
  in {
    inherit packages buildSystem targets;
  };

  # Test realistic usage scenarios
  scenarios = {
    # Scenario 1: Developer on ARM Mac wanting to build for multiple targets
    arm_mac_multi_target = mockRustnixUsage {
      buildSystem = "aarch64-darwin";
      targets = ["aarch64-linux" "x86_64-linux" "aarch64-darwin"];
      cargoToml = {
        package = {
          name = "my-cli";
          version = "1.0.0";
        };
      };
    };

    # Scenario 2: CI on x86_64 Linux building for release targets
    ci_x86_multi_target = mockRustnixUsage {
      buildSystem = "x86_64-linux";
      targets = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
      cargoToml = {
        package = {
          name = "server";
          version = "2.1.0";
        };
      };
    };

    # Scenario 3: Single target build on ARM Mac for ARM Linux
    arm_mac_to_arm_linux = mockRustnixUsage {
      buildSystem = "aarch64-darwin";
      targets = ["aarch64-linux"];
      cargoToml = {
        package = {
          name = "app";
          version = "0.1.0";
        };
      };
    };
  };

  # Usage patterns and commands
  usagePatterns = {
    "Developer workflow" = {
      description = "ARM Mac developer building for Linux servers";
      commands = [
        "nix build .#packages.aarch64-linux.my-cli" # ARM Linux
        "nix build .#packages.x86_64-linux.my-cli" # x86 Linux
        "nix build .#my-cli" # Current system (ARM Mac)
      ];
      buildSystem = "aarch64-darwin";
      note = "Uses ARM Mac toolchain to cross-compile for Linux targets";
    };

    "CI/CD workflow" = {
      description = "x86 Linux CI building release artifacts";
      commands = [
        "nix build .#packages.x86_64-linux.server" # Native Linux
        "nix build .#packages.aarch64-linux.server" # Cross to ARM Linux
        "nix build .#packages.x86_64-darwin.server" # Cross to Intel Mac
        "nix build .#packages.aarch64-darwin.server" # Cross to ARM Mac
      ];
      buildSystem = "x86_64-linux";
      note = "Uses x86 Linux toolchain to cross-compile for all targets";
    };

    "Wrong approach" = {
      description = "DON'T use --system for cross-compilation";
      commands = [
        "nix build --system aarch64-linux .#my-cli" # WRONG: tries to emulate ARM
      ];
      buildSystem = "varies";
      note = "This forces emulation/remote builders instead of cross-compilation";
    };
  };

  # Validations
  validations = {
    # Verify cross-compilation detection works correctly
    crossCompilationDetection = let
      armMacPackages = scenarios.arm_mac_multi_target.packages;
    in
      assert armMacPackages."aarch64-linux".isCrossCompiling == true; # Cross-compile
      
      assert armMacPackages."x86_64-linux".isCrossCompiling == true; # Cross-compile
      
      assert armMacPackages."aarch64-darwin".isCrossCompiling == false; # Native
      
        "✓ Cross-compilation detection works correctly";

    # Verify toolchain selection
    toolchainSelection = let
      ciPackages = scenarios.ci_x86_multi_target.packages;
    in
      assert ciPackages."aarch64-linux".toolchainFrom == "x86_64-linux";
      assert ciPackages."x86_64-darwin".toolchainFrom == "x86_64-linux";
      assert ciPackages."x86_64-linux".toolchainFrom == "x86_64-linux"; "✓ Toolchain always comes from build system";

    # Verify nixpkgs configuration
    nixpkgsConfiguration = let
      armPackages = scenarios.arm_mac_to_arm_linux.packages;
      armLinuxPkg = armPackages."aarch64-linux";
    in
      assert armLinuxPkg.nixpkgsConfig.system == "aarch64-darwin";
      assert armLinuxPkg.nixpkgsConfig ? crossSystem;
      assert armLinuxPkg.nixpkgsConfig.crossSystem.config == "aarch64-unknown-linux-musl"; "✓ Nixpkgs configuration is correct";

    # Verify package naming
    packageNaming = let
      packages = scenarios.arm_mac_multi_target.packages;
    in
      assert packages."aarch64-linux".packageName == "my-cli-aarch64-linux";
      assert packages."x86_64-linux".packageName == "my-cli-x86_64-linux"; "✓ Package naming includes target system";
  };

  # Best practices
  bestPractices = {
    "Use multi-system packages" = "Build with .#packages.target-system.package";
    "Don't use --system for cross-compilation" = "Use explicit target selection instead";
    "Build system provides toolchain" = "Fenix packages come from your actual machine";
    "Target system gets the output" = "Binary runs on the target you specified";
    "Archive for distribution" = "Use archiveAndHash=true for release artifacts";
  };
in {
  inherit scenarios usagePatterns validations bestPractices;

  # Run all validations
  runTests = lib.mapAttrs (name: validation: validation) validations;

  summary = "Correct usage scenarios validated successfully";

  insight = ''
    Correct rustnix usage:
    1. Use .#packages.target-system.package for cross-compilation
    2. Build system (your machine) provides the toolchain
    3. Target system (in package path) gets the binary
    4. No need for --system flag - it's handled automatically
  '';
}
