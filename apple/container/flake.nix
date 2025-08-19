{
  description = "Apple Container with Swift 6";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    apple-container = {
      url = "github:apple/container";
      flake = false;
    };
  };
  outputs = {
    apple-container,
    flake-utils,
    nixpkgs,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};

      # Use official Swift 6.1.2 release - much more reliable than building from source
      swift6 = pkgs.stdenv.mkDerivation rec {
        pname = "swift";
        version = "6.1.2";

        src =
          if pkgs.stdenv.isDarwin
          then
            pkgs.fetchurl {
              url = "https://download.swift.org/swift-6.1.2-release/xcode/swift-6.1.2-RELEASE/swift-6.1.2-RELEASE-osx.pkg";
              sha256 = "sha256-Rs1x8O5NgOOJSUwSNzNaCk9DqK2gT82XsilT1vKhTWc="; # Will be updated by nix
            }
          else
            pkgs.fetchurl {
              url = "https://download.swift.org/swift-6.1.2-release/ubuntu2404/swift-6.1.2-RELEASE/swift-6.1.2-RELEASE-ubuntu24.04.tar.gz";
              sha256 = "0000000000000000000000000000000000000000000000000000"; # Will be updated by nix
            };

        nativeBuildInputs = with pkgs;
          [
            makeWrapper
          ]
          ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            xar
            cpio
          ];

        unpackPhase =
          if pkgs.stdenv.isDarwin
          then ''
            echo "Extracting Swift .pkg file..."
            xar -xf $src

            # Find the actual payload
            payload_file=$(find . -name "Payload" | head -1)
            if [ -n "$payload_file" ]; then
              cd "$(dirname "$payload_file")"
              cat Payload | gunzip -dc | cpio -i
            else
              echo "Could not find Payload in .pkg"
              exit 1
            fi
          ''
          else ''
            echo "Extracting Swift tarball..."
            tar -xzf $src --strip-components=1
          '';

        installPhase =
          if pkgs.stdenv.isDarwin
          then ''
            mkdir -p $out
            # The .pkg extracts to usr/
            if [ -d "usr" ]; then
              cp -r usr/* $out/
            else
              # Fallback: copy everything
              cp -r * $out/
            fi
          ''
          else ''
            mkdir -p $out
            cp -r * $out/
          '';

        postInstall = ''
          # Wrap Swift binaries to ensure they can find libraries
          for binary in $out/bin/*; do
            if [ -f "$binary" ] && [ -x "$binary" ]; then
              wrapProgram "$binary" \
                --prefix DYLD_LIBRARY_PATH : "$out/lib" \
                --prefix LD_LIBRARY_PATH : "$out/lib"
            fi
          done
        '';

        meta = with pkgs.lib; {
          description = "Swift Programming Language 6.1.2 (Official Release)";
          homepage = "https://swift.org";
          license = licenses.asl20;
          platforms = platforms.unix;
        };
      };

      apple-container' = pkgs.stdenv.mkDerivation {
        pname = "apple-container";
        version = "custom";
        src = apple-container;

        nativeBuildInputs = with pkgs; [
          git
          makeWrapper
          pkg-config
        ];

        buildInputs =
          [swift6]
          ++ (with pkgs; [
            libxml2
            curl
          ])
          ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            pkgs.darwin.apple_sdk.frameworks.Foundation
            pkgs.darwin.apple_sdk.frameworks.Security
            pkgs.darwin.apple_sdk.frameworks.CoreFoundation
            pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
            pkgs.darwin.system_cmds
          ];

        configurePhase = ''
          # Ensure Swift 6 is in PATH
          export PATH="${swift6}/bin:$PATH"
          export PKG_CONFIG_PATH="${pkgs.libxml2.dev}/lib/pkgconfig:$PKG_CONFIG_PATH"

          # Verify Swift is working
          echo "Swift version check:"
          swift --version || {
            echo "Error: Swift 6 not available"
            exit 1
          }
        '';

        buildPhase = ''
          export PATH="${swift6}/bin:$PATH"

          echo "Building apple-container..."

          # Try different build approaches
          if [ -f "Package.swift" ]; then
            echo "Using Swift Package Manager..."
            swift build --configuration release
          elif [ -f "Makefile" ]; then
            echo "Using Makefile..."
            make SWIFT="${swift6}/bin/swift" SWIFTC="${swift6}/bin/swiftc"
          else
            echo "Attempting to find and compile Swift sources..."
            swift_files=$(find . -name "*.swift" -type f)
            if [ -n "$swift_files" ]; then
              echo "Compiling Swift files: $swift_files"
              swiftc $swift_files -o container
            else
              echo "Error: No Swift files or build system found"
              ls -la
              exit 1
            fi
          fi
        '';

        installPhase = ''
          mkdir -p $out/bin $out/lib

          # Install built binaries
          if [ -f ".build/release/container" ]; then
            cp .build/release/container $out/bin/
          elif [ -f "container" ]; then
            cp container $out/bin/
          elif [ -d ".build/release" ]; then
            # Copy all executables from build directory
            find .build/release -maxdepth 1 -type f -executable -exec cp {} $out/bin/ \;
          fi

          # Install any libraries
          find . \( -name "*.so" -o -name "*.dylib" \) -type f 2>/dev/null | while read lib; do
            cp "$lib" $out/lib/
          done

          # Wrap binaries to ensure they can find Swift runtime
          for binary in $out/bin/*; do
            if [ -f "$binary" ] && [ -x "$binary" ]; then
              wrapProgram "$binary" \
                --prefix PATH : "${swift6}/bin" \
                --prefix LD_LIBRARY_PATH : "${swift6}/lib:$out/lib" \
                --prefix DYLD_LIBRARY_PATH : "${swift6}/lib:$out/lib"
            fi
          done

          # If no binaries were found, this might not be an executable project
          if [ ! -f "$out/bin/"* ]; then
            echo "Warning: No executables found. This might be a library project."
            # Copy everything as a library/source package
            mkdir -p $out/share/apple-container
            cp -r . $out/share/apple-container/
          fi
        '';

        meta = with pkgs.lib; {
          description = "Apple Container built with Swift 6";
          homepage = "https://github.com/apple/container";
          platforms = platforms.unix;
        };
      };
    in {
      packages = {
        default = apple-container';
        swift6 = swift6;
        apple-container = apple-container';
      };

      devShells.default = pkgs.mkShell {
        buildInputs =
          [swift6]
          ++ (with pkgs; [
            git
            pkg-config
            libxml2
            curl
          ]);

        shellHook = ''
          echo "Apple Container development environment with Swift 6"
          echo "Swift version: $(swift --version 2>/dev/null || echo 'Swift not yet built')"
          echo ""
          echo "To build Swift 6 first: nix build .#swift6"
          echo "To build apple-container: nix build .#apple-container"
        '';
      };
    });
}
