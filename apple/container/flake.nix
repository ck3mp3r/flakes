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
        # Use a derivation to find Xcode path at build time, but make it available at eval time
        findXcode = pkgs.runCommand "find-xcode" {} ''
          xcode_path=$(find /nix/store -maxdepth 1 -name "*Xcode-beta.app" -type d | head -1)
          if [ -z "$xcode_path" ]; then
            echo "Error: Could not find Xcode-beta.app in /nix/store" >&2
            exit 1
          fi
          echo -n "$xcode_path" > $out
        '';

        # Read the Xcode path
        xcodeBetaPath = builtins.readFile findXcode;

        # Derive other paths from the found Xcode path
        xcodeSDKPath = "${xcodeBetaPath}/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk";
        xcodeDeveloperDir = "${xcodeBetaPath}/Contents/Developer";
        xcodeToolchainPath = "${xcodeBetaPath}/Contents/Developer/Toolchains/XcodeDefault.xctoolchain";

        # Create overlay that uses Swift from Xcode 26 beta
        swiftOverlay = final: prev: {
          swift = final.stdenv.mkDerivation {
            pname = "swift";
            version = "6.2-beta";

            nativeBuildInputs = with final; [makeWrapper];
            src = final.emptyDirectory;

            dontUnpack = true;
            dontConfigure = true;
            dontBuild = true;

            installPhase = ''
              echo "Using Xcode 26 beta at: ${xcodeBetaPath}"
              echo "Using SDK: ${xcodeSDKPath}"

              mkdir -p $out/bin

              # Create wrapper scripts that point to Xcode's Swift
              for tool in swift swiftc; do
                if [ -f "${xcodeToolchainPath}/usr/bin/$tool" ]; then
                  makeWrapper "${xcodeToolchainPath}/usr/bin/$tool" "$out/bin/$tool" \
                    --set DEVELOPER_DIR "${xcodeDeveloperDir}" \
                    --set SDKROOT "${xcodeSDKPath}"
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

        # Build the container package ONCE
        apple-container = pkgs.stdenv.mkDerivation {
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

            # Set macOS 26 deployment target and Xcode environment
            export MACOSX_DEPLOYMENT_TARGET=26.0
            export DEVELOPER_DIR="${xcodeDeveloperDir}"
            export SDKROOT="${xcodeSDKPath}"

            echo "Building apple-container with Swift 6.2 for macOS 26..."
            echo "Using Xcode: ${xcodeBetaPath}"
            echo "Using SDK: ${xcodeSDKPath}"

            # Set up containerization dependency as sibling directory
            mkdir -p ../containerization
            cp -r ${containerization-src}/* ../containerization/

            # Patch Package.swift to remove problematic swift-docc-plugin
            if [ -f Package.swift ]; then
              echo "Patching Package.swift to remove swift-docc-plugin..."
              sed -i.bak '/swift-docc-plugin/d' Package.swift
              sed -i.bak '/SwiftDocCPlugin/d' Package.swift
              sed -i.bak '/\.plugin(/d' Package.swift
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
              -Xswiftc "-sdk" -Xswiftc "${xcodeSDKPath}"
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
        };

        packages = {
          default = apple-container;
          swift6 = pkgs.swift;
        };

        apps = {
          default = {
            type = "app";
            program = "${apple-container}/bin/container";
          };
        };
      }
    );
}
