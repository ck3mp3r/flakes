{
  pkgs,
  apple-container,
}: {
  buildInputs = with pkgs; [
    apple-container
    swift
    xar
    bd
    cpio
  ];

  shellHook = ''
    export SWIFTPM_DISABLE_SANDBOX=1
    export MACOSX_DEPLOYMENT_TARGET=26.0

    echo "🍎 Apple Container Development Environment"
    echo "=========================================="
    echo ""
    echo "Available commands:"
    echo "  • add-xcode-to-store   - Add extracted Xcode.app to Nix store"
    echo "  • setup-xcode          - Set up Xcode for macOS 26 development"
    echo "  • build-container      - Build Apple Container with Swift 6.2"
    echo "  • test-container       - Run Apple Container tests"
    echo "  • swift-info           - Show Swift configuration"
    echo "  • xcode-info           - Show Xcode configuration"
    echo "  • clean-build          - Clean build artifacts"
    echo "  • quick-build          - Quick debug build"
    echo ""
    echo "Available packages:"
    echo "  • container: ${apple-container}/bin/container"
    echo "  • swift: $(which swift)"
    echo ""
    echo "Environment:"
    echo "  • MACOSX_DEPLOYMENT_TARGET=26.0"
    echo "  • SWIFTPM_DISABLE_SANDBOX=1"
  '';

  packages = with pkgs; [
    (writeShellApplication {
      name = "add-xcode-to-store";
      text = ''
        echo "🔧 Adding Existing Xcode to Nix Store"
        echo "====================================="
        echo ""

        if [ ! -d "/Applications/Xcode-beta.app" ]; then
          echo "❌ Xcode.app not found"
          exit 1
        fi

        echo "✅ Found Xcode.app"

        sdk_path="/Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs"
        if [ -d "$sdk_path" ]; then
          echo "✅ Found macOS SDK"
        fi

        echo "📦 Adding Xcode.app to Nix store..."
        store_path=$(nix-store --add-fixed --recursive sha256 /Applications/Xcode-beta.app)
        hash=$(nix-store --query --hash "$store_path")

        echo "✅ Successfully added to Nix store!"
        echo "Store path: $store_path"
        echo "SHA256: $hash"
      '';
    })

    (writeShellApplication {
      name = "setup-xcode";
      text = ''
        echo "🔧 Xcode Setup Check"
        echo "==================="
        if [ -d "/Applications/Xcode.app" ]; then
          echo "✅ Found system Xcode"
          xcode_version=$(xcodebuild -version 2>/dev/null | head -1 || echo "Unknown")
          echo "Version: $xcode_version"
        else
          echo "❌ No system Xcode found"
        fi
      '';
    })

    (writeShellApplication {
      name = "build-container";
      text = ''
        echo "🚀 Building Apple Container"
        export SWIFTPM_DISABLE_SANDBOX=1
        export MACOSX_DEPLOYMENT_TARGET=26.0

        if [ -f "Package.swift" ]; then
          swift build --configuration release --disable-sandbox -v
          echo "✅ Build complete!"
        else
          echo "❌ No Package.swift found"
        fi
      '';
    })

    (writeShellApplication {
      name = "test-container";
      text = ''
        echo "🧪 Testing Apple Container"
        export SWIFTPM_DISABLE_SANDBOX=1
        export MACOSX_DEPLOYMENT_TARGET=26.0

        if [ -f "Package.swift" ]; then
          swift test --disable-sandbox
        else
          echo "❌ No Package.swift found"
        fi
      '';
    })

    (writeShellApplication {
      name = "swift-info";
      text = ''
        echo "Swift Development"
        swift --version
      '';
    })

    (writeShellApplication {
      name = "xcode-info";
      text = ''
        if [ -d "/Applications/Xcode.app" ]; then
          xcodebuild -version 2>/dev/null || echo "Version: Unknown"
        else
          echo "❌ No system Xcode found"
        fi
      '';
    })

    (writeShellApplication {
      name = "clean-build";
      text = ''
        if [ -f "Package.swift" ]; then
          swift package clean
          rm -rf .build
          echo "✅ Clean complete"
        else
          echo "❌ No Package.swift found"
        fi
      '';
    })

    (writeShellApplication {
      name = "quick-build";
      text = ''
        if [ -f "Package.swift" ]; then
          export SWIFTPM_DISABLE_SANDBOX=1
          swift build --disable-sandbox
        else
          echo "❌ No Package.swift found"
        fi
      '';
    })
  ];
}
