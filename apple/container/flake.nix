{
  description = "Apple Container - A container platform for macOS";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    devshell.url = "github:numtide/devshell";
    # Apple Container source
    container-src = {
      url = "github:apple/container";
      flake = false;
    };
    # Apple Containerization framework source
    containerization-src = {
      url = "github:apple/containerization/0.5.0";
      flake = false;
    };
  };
  outputs = {
    nixpkgs,
    flake-utils,
    devshell,
    container-src,
    containerization-src,
    ...
  }:
    flake-utils.lib.eachSystem ["aarch64-darwin" "x86_64-darwin"] (
      system: let
        # Create overlay that uses Swift from Xcode 26 beta
        swiftOverlay = final: prev: {
          swift = final.stdenv.mkDerivation rec {
            pname = "swift";
            version = "6.2-beta";

            nativeBuildInputs = with final; [makeWrapper];
            src = final.emptyDirectory;

            dontUnpack = true;
            dontConfigure = true;
            dontBuild = true;

            installPhase = ''
              # Find Xcode 26 beta in nix store
              xcode_path=$(find /nix/store -maxdepth 1 -name "*Xcode-beta.app" -type d | head -1)

              if [ -z "$xcode_path" ]; then
                echo "Error: Could not find Xcode-beta.app in /nix/store"
                exit 1
              fi

              echo "Found Xcode 26 beta at: $xcode_path"

              mkdir -p $out/bin

              # Find the macOS 26 SDK
              sdk_path="$xcode_path/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs"
              macos_sdk=$(find "$sdk_path" -name "MacOSX*.sdk" -type d | head -1)

              echo "Using SDK: $macos_sdk"

              # Create wrapper scripts that point to Xcode's Swift
              toolchain_path="$xcode_path/Contents/Developer/Toolchains/XcodeDefault.xctoolchain"

              for tool in swift swiftc; do
                if [ -f "$toolchain_path/usr/bin/$tool" ]; then
                  makeWrapper "$toolchain_path/usr/bin/$tool" "$out/bin/$tool" \
                    --set DEVELOPER_DIR "$xcode_path/Contents/Developer" \
                    --set SDKROOT "$macos_sdk"
                fi
              done
            '';

            meta = with final.lib; {
              description = "Swift Programming Language 6.2 from Xcode 26 Beta";
              platforms = platforms.darwin;
              license = licenses.unfree;
            };
          };
        };

        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            devshell.overlays.default
            swiftOverlay
          ];
        };
      in {
        devShells.default = pkgs.devshell.mkShell {
          imports = [(pkgs.devshell.importTOML ./devshell.toml)];
          packages = with pkgs; [
            swift # Swift 6.2 from Xcode 26 beta
            git
            gnumake
            darwin.system_cmds # Provides sw_vers
            cacert # Fix SSL certificate issues
          ];
          env = [
            {
              name = "SWIFT_EXEC";
              value = "${pkgs.swift}/bin/swift";
            }
            {
              name = "CONTAINER_SRC";
              value = "${container-src}";
            }
            {
              name = "CONTAINERIZATION_SRC";
              value = "${containerization-src}";
            }
          ];
        };

        packages = {
          default = pkgs.stdenv.mkDerivation {
            pname = "apple-container";
            version = "1.0.0";
            src = container-src;

            nativeBuildInputs = with pkgs; [
              swift
              git
              gnumake
              darwin.system_cmds
              cacert
            ];

            buildPhase = ''
              export PATH="${pkgs.swift}/bin:$PATH"
              export SWIFTPM_DISABLE_SANDBOX=1
              export CONTAINER_SRC="${container-src}"
              export CONTAINERIZATION_SRC="${containerization-src}"

              # Fix SSL certificates
              export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
              export NIX_SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

              # Set macOS 26 deployment target
              export MACOSX_DEPLOYMENT_TARGET=26.0

              # Find Xcode and SDK
              xcode_path=$(find /nix/store -maxdepth 1 -name "*Xcode-beta.app" -type d | head -1)
              sdk_path="$xcode_path/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs"
              macos_sdk=$(find "$sdk_path" -name "MacOSX*.sdk" -type d | head -1)

              export DEVELOPER_DIR="$xcode_path/Contents/Developer"
              export SDKROOT="$macos_sdk"

              echo "Building apple-container with Swift 6.2 for macOS 26..."
              echo "Using Xcode: $xcode_path"
              echo "Using SDK: $macos_sdk"

              # Set up containerization dependency as sibling directory
              mkdir -p ../containerization
              cp -r ${containerization-src}/* ../containerization/

              # Patch Package.swift to remove problematic swift-docc-plugin
              if [ -f Package.swift ]; then
                echo "Patching Package.swift to remove swift-docc-plugin..."
                # Use proper sed syntax for macOS
                sed -i.bak '/swift-docc-plugin/d' Package.swift
                sed -i.bak '/SwiftDocCPlugin/d' Package.swift
                sed -i.bak '/\.plugin(/d' Package.swift
                # Remove backup files
                rm -f Package.swift.bak
                echo "Package.swift patched"
              fi

              # Build with Swift Package Manager
              echo "Building with Swift Package Manager..."
              export SWIFTPM_CACHE_PATH="$TMPDIR/swiftpm-cache"
              mkdir -p "$SWIFTPM_CACHE_PATH"

              swift build --configuration release \
                --disable-sandbox \
                --scratch-path "$TMPDIR/swift-build" \
                -Xswiftc "-target" -Xswiftc "arm64-apple-macosx26.0" \
                -Xswiftc "-sdk" -Xswiftc "$macos_sdk"
            '';

            installPhase = ''
              mkdir -p $out/bin

              # Look for the built executable
              if [ -f ".build/release/container" ]; then
                cp .build/release/container $out/bin/
                echo "Installed container executable"
              elif [ -f "$TMPDIR/swift-build/release/container" ]; then
                cp "$TMPDIR/swift-build/release/container" $out/bin/
                echo "Installed container executable from scratch path"
              else
                echo "Warning: No container executable found"
                echo "Available files in .build:"
                find .build -name "*container*" 2>/dev/null || echo "No .build directory"
                echo "Available files in scratch path:"
                find "$TMPDIR/swift-build" -name "*container*" 2>/dev/null || echo "No scratch build directory"

                # Still install source for debugging
                mkdir -p $out/share/apple-container
                cp -r . $out/share/apple-container/
                echo "Installed source code for debugging"
              fi
            '';

            meta = with pkgs.lib; {
              description = "Apple Container - A container platform for macOS 26";
              homepage = "https://github.com/apple/container";
              platforms = platforms.darwin;
              license = licenses.unfree;
            };
          };
          swift6 = pkgs.swift;
        };

        apps = {
          default = {
            type = "app";
            program = "${pkgs.stdenv.mkDerivation {
              pname = "apple-container-app";
              version = "1.0.0";
              src = container-src;

              nativeBuildInputs = with pkgs; [
                swift
                git
                gnumake
                darwin.system_cmds
                cacert
              ];

              buildPhase = ''
                export PATH="${pkgs.swift}/bin:$PATH"
                export SWIFTPM_DISABLE_SANDBOX=1
                export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
                export MACOSX_DEPLOYMENT_TARGET=26.0

                # Find Xcode and SDK
                xcode_path=$(find /nix/store -maxdepth 1 -name "*Xcode-beta.app" -type d | head -1)
                sdk_path="$xcode_path/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs"
                macos_sdk=$(find "$sdk_path" -name "MacOSX*.sdk" -type d | head -1)

                export DEVELOPER_DIR="$xcode_path/Contents/Developer"
                export SDKROOT="$macos_sdk"

                # Set up containerization dependency
                mkdir -p ../containerization
                cp -r ${containerization-src}/* ../containerization/

                # Patch and build
                if [ -f Package.swift ]; then
                  sed -i.bak '/swift-docc-plugin/d' Package.swift
                  sed -i.bak '/SwiftDocCPlugin/d' Package.swift
                  sed -i.bak '/\.plugin(/d' Package.swift
                  rm -f Package.swift.bak
                fi

                export SWIFTPM_CACHE_PATH="$TMPDIR/swiftpm-cache"
                mkdir -p "$SWIFTPM_CACHE_PATH"

                swift build --configuration release \
                  --disable-sandbox \
                  --scratch-path "$TMPDIR/swift-build" \
                  -Xswiftc "-target" -Xswiftc "arm64-apple-macosx26.0" \
                  -Xswiftc "-sdk" -Xswiftc "$macos_sdk"
              '';

              installPhase = ''
                mkdir -p $out/bin
                if [ -f ".build/release/container" ]; then
                  cp .build/release/container $out/bin/
                elif [ -f "$TMPDIR/swift-build/release/container" ]; then
                  cp "$TMPDIR/swift-build/release/container" $out/bin/
                else
                  echo "#!/bin/bash" > $out/bin/container
                  echo "echo 'Container executable not found during build'" >> $out/bin/container
                  chmod +x $out/bin/container
                fi
              '';
            }}/bin/container";
          };
        };
      }
    );
}
