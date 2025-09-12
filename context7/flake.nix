{
  description = "Context7 MCP Server - Up-to-date code documentation for LLMs and AI code editors";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    context7-src = {
      url = "github:upstash/context7/v1.0.17";
      flake = false;
    };
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    context7-src,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config = {allowUnfree = true;};
        };

        context7-mcp = pkgs.stdenv.mkDerivation {
          pname = "@upstash/context7-mcp";
          version = "1.0.17";

          src = context7-src;

          nativeBuildInputs = with pkgs; [
            nodejs_20
            typescript
            bun
          ];

          configurePhase = ''
            runHook preConfigure
            export HOME=$TMPDIR
            ${pkgs.bun}/bin/bun install --frozen-lockfile
            runHook postConfigure
          '';

          buildPhase = ''
            runHook preBuild
            ${pkgs.bun}/bin/bun run build
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out/lib/node_modules/@upstash/context7-mcp
            cp -r dist package.json node_modules $out/lib/node_modules/@upstash/context7-mcp/
            mkdir -p $out/bin
            cat > $out/bin/context7-mcp << EOF
            #!/usr/bin/env node
            require('$out/lib/node_modules/@upstash/context7-mcp/dist/index.js')
            EOF
            chmod +x $out/bin/context7-mcp
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Context7 MCP Server - Up-to-date code documentation for LLMs and AI code editors";
            homepage = "https://github.com/upstash/context7";
            license = licenses.mit;
            maintainers = [];
            platforms = platforms.all;
          };
        };
      in {
        packages.default = context7-mcp;
        packages.context7-mcp = context7-mcp;

        apps.default = {
          type = "app";
          program = "${context7-mcp}/bin/context7-mcp";
        };
      }
    )
    // {
      overlays.default = final: prev: {
        context7-mcp = self.packages.default;
      };
    };
}
