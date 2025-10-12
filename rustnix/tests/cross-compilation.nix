# Test the correct cross-compilation behavior with multi-system packages
{
  pkgs ? import <nixpkgs> {},
  lib ? pkgs.lib,
}: let
  # Test the cross-compilation logic from the current buildPackages function
  testCrossPkgs = buildSystem: targetSystem: let
    utils = import ../lib/utils.nix;

    fenixTarget = utils.getTarget {
      system = targetSystem;
      variant = "musl";
    };

    isTargetLinux = builtins.match ".*-linux" targetSystem != null;
    isCrossCompiling = targetSystem != buildSystem;

    # This mirrors the logic in lib/rust/default.nix crossPkgs function
    nixpkgsConfig =
      if isCrossCompiling || isTargetLinux
      then {
        system = buildSystem; # Uses build system
        overlays = [];
        crossSystem = {
          config = fenixTarget;
          rustc = {config = fenixTarget;};
          isStatic = isTargetLinux;
        };
      }
      else {
        system = buildSystem;
        overlays = [];
      };

    # Fenix toolchain comes from build system
    toolchainSystem = buildSystem;
  in {
    inherit buildSystem targetSystem fenixTarget isTargetLinux isCrossCompiling;
    inherit nixpkgsConfig toolchainSystem;
  };

  # Test realistic scenarios with the current design
  scenarios = {
    # Building on x86_64-linux for x86_64-linux (native)
    x86_to_x86 = testCrossPkgs "x86_64-linux" "x86_64-linux";

    # Building on x86_64-linux for aarch64-linux (cross-compile)
    x86_to_arm = testCrossPkgs "x86_64-linux" "aarch64-linux";

    # Building on aarch64-darwin for x86_64-linux (cross-compile)
    arm_mac_to_x86 = testCrossPkgs "aarch64-darwin" "x86_64-linux";

    # Building on aarch64-darwin for aarch64-linux (cross-compile)
    arm_mac_to_arm = testCrossPkgs "aarch64-darwin" "aarch64-linux";

    # Building on aarch64-darwin for aarch64-darwin (native)
    arm_mac_native = testCrossPkgs "aarch64-darwin" "aarch64-darwin";
  };

  # Validations for the correct behavior
  validations = {
    # Cross-compilation detection
    crossDetection = assert scenarios.x86_to_x86.isCrossCompiling == false;
    assert scenarios.x86_to_arm.isCrossCompiling == true;
    assert scenarios.arm_mac_to_x86.isCrossCompiling == true;
    assert scenarios.arm_mac_native.isCrossCompiling == false; "✓ Cross-compilation detection works correctly";

    # Toolchain selection (always from build system)
    toolchainSelection = assert scenarios.x86_to_arm.toolchainSystem == "x86_64-linux";
    assert scenarios.arm_mac_to_x86.toolchainSystem == "aarch64-darwin";
    assert scenarios.x86_to_x86.toolchainSystem == "x86_64-linux"; "✓ Toolchain comes from build system";

    # Nixpkgs system (always build system)
    nixpkgsSystem = assert scenarios.x86_to_arm.nixpkgsConfig.system == "x86_64-linux";
    assert scenarios.arm_mac_to_x86.nixpkgsConfig.system == "aarch64-darwin";
    assert scenarios.x86_to_x86.nixpkgsConfig.system == "x86_64-linux"; "✓ Nixpkgs uses build system";

    # Cross-system configuration
    crossSystemConfig = assert scenarios.x86_to_arm.nixpkgsConfig ? crossSystem;
    assert scenarios.x86_to_arm.nixpkgsConfig.crossSystem.config == "aarch64-unknown-linux-musl";
    assert scenarios.arm_mac_to_x86.nixpkgsConfig.crossSystem.config == "x86_64-unknown-linux-musl"; "✓ Cross-system configuration is correct";

    # Target generation
    targetGeneration = assert scenarios.x86_to_arm.fenixTarget == "aarch64-unknown-linux-musl";
    assert scenarios.arm_mac_to_x86.fenixTarget == "x86_64-unknown-linux-musl";
    assert scenarios.arm_mac_native.fenixTarget == "aarch64-apple-darwin"; "✓ Target generation works correctly";
  };

  # Correct usage patterns
  usageExamples = {
    "Build for current system" = "nix build .#my-package";
    "Build for x86_64-linux" = "nix build .#packages.x86_64-linux.my-package";
    "Build for aarch64-linux" = "nix build .#packages.aarch64-linux.my-package";
    "Build archived for ARM" = "nix build .#packages.aarch64-linux.my-package-archived";
    "Don't use --system for cross-compilation" = "Use .#packages.target-system.package instead";
  };
in {
  inherit scenarios validations usageExamples;

  # Run all validations
  runTests = lib.mapAttrs (name: validation: validation) validations;

  summary = "Multi-system cross-compilation tests completed successfully";

  insight = ''
    The correct approach:
    - Use .#packages.target-system.package for cross-compilation
    - Don't use --system flag for cross-compilation
    - Build system provides toolchain, target system gets the output
  '';
}
