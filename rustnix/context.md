# Rustnix Cross-Compilation Fix Context

## Problem
The current `buildTargetOutputs` function creates a confusing nested package structure when used with `flake-utils.lib.eachDefaultSystem`.

### Current Bad Output:
```
packages.aarch64-darwin.
├── aarch64-darwin    # ← Redundant nesting
├── aarch64-linux     # ← Wrong! ARM Linux package under ARM Darwin system
├── x86_64-linux      # ← Wrong! x86 Linux package under ARM Darwin system
├── c67-mcp           # ← Named package
└── default           # ← Default package
```

This happens because `buildTargetOutputs` returns ALL target packages as an attribute set, and `eachDefaultSystem` puts this entire set under each system.

## Root Cause
```nix
# Current broken design
flake-utils.lib.eachDefaultSystem (system: {
  packages = buildTargetOutputs {
    supportedTargets = ["aarch64-darwin" "aarch64-linux" "x86_64-linux"];
    # Returns: { aarch64-darwin = ...; aarch64-linux = ...; x86_64-linux = ...; }
  };
})
# Results in packages.SYSTEM.TARGET structure (wrong!)
```

## Solution
Change `buildTargetOutputs` to only return the package for the **current system**, not all targets.

### Expected Good Output:
```
packages.aarch64-darwin.default   # Only ARM Darwin package
packages.aarch64-linux.default    # Only ARM Linux package
packages.x86_64-linux.default     # Only x86 Linux package
```

## Implementation Plan

### 1. Modify buildTargetOutputs logic
- Check if current `system` is in `supportedTargets`
- If yes: build package for current system only
- If no: return empty set (no package for unsupported system)
- Keep cross-compilation logic but only return one result

### 2. Update return structure
Instead of:
```nix
# Current (wrong)
{
  aarch64-darwin = derivation;
  aarch64-linux = derivation;
  x86_64-linux = derivation;
  default = derivation;
  packageName = derivation;
}
```

Return:
```nix
# New (correct)
{
  default = derivation;        # Package for current system
  packageName = derivation;    # Named package (if provided)
  # aliases...
}
# OR empty {} if system not in supportedTargets
```

### 3. Benefits
- ✅ Clean flake output structure
- ✅ Each system gets only its own package
- ✅ Cross-compilation still works (build system ≠ target system)
- ✅ `supportedTargets` still declares what the package supports
- ✅ Works correctly with `flake-utils.lib.eachDefaultSystem`

### 4. Breaking Changes
- Consuming flakes will need to update usage
- Remove confusing nested target structure
- Simpler, more intuitive API

## Files to Update
- `lib/rust/default.nix` - Main logic changes
- `README.md` - Update examples and documentation
- `tests/` - Update test expectations
- Remove `packageOutputs` and `binaryOutputs` complexity
