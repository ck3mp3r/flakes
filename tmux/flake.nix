{
  description = "Portable tmux configuration with custom plugins and system monitoring";

  inputs = {
    base-nixpkgs.url = "github:ck3mp3r/flakes?dir=base-nixpkgs";
    nixpkgs.follows = "base-nixpkgs/unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];

      perSystem = {pkgs, ...}: let
        # Fetch catppuccin theme
        catppucinSrc = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "tmux";
          rev = "8b0b9150f9d7dee2a4b70cdb50876ba7fd6d674a";
          sha256 = "godCgBMgqzim+W3O2sHcgw91h7sHsKHjd02BdLuazZ8=";
        };

        # Custom catppuccin status modules
        catppuccinStatusSrc = ./plugins/catppuccin;

        # Merge catppuccin base with custom status modules
        mergedSources = pkgs.stdenvNoCC.mkDerivation {
          name = "mergedSources";
          buildInputs = with pkgs; [rsync];

          buildCommand = ''
            mkdir -p $out
            rsync -a ${catppucinSrc}/. $out/
            rsync -a ${catppuccinStatusSrc}/. $out/
          '';
        };

        # Custom tmux-catppuccin plugin
        tmux-catppuccin = pkgs.tmuxPlugins.mkTmuxPlugin {
          name = "catppuccin";
          pluginName = "catppuccin";
          src = mergedSources;
        };

        # Custom monitoring plugin - handles CPU, RAM, GPU, Battery
        tmux-monitor = pkgs.tmuxPlugins.mkTmuxPlugin {
          name = "monitor";
          pluginName = "monitor";
          src = pkgs.runCommand "monitor-plugin-src" {} ''
            mkdir -p $out/scripts

            # Copy non-templated files
            cp ${./plugins/monitor}/scripts/cpu_*.sh $out/scripts/
            cp ${./plugins/monitor}/scripts/ram_*.sh $out/scripts/
            cp ${./plugins/monitor}/scripts/gpu_*.sh $out/scripts/

            # Use replaceVars for templated files
            cp ${pkgs.replaceVars ./plugins/monitor/scripts/helpers.sh {tmuxBin = pkgs.tmux;}} $out/scripts/helpers.sh
            cp ${pkgs.replaceVars ./plugins/monitor/monitor.tmux {tmuxBin = pkgs.tmux;}} $out/monitor.tmux
            cp ${pkgs.replaceVars ./plugins/monitor/scripts/battery_percentage.sh {tmuxPluginsBattery = pkgs.tmuxPlugins.battery;}} $out/scripts/battery_percentage.sh
            cp ${pkgs.replaceVars ./plugins/monitor/scripts/battery_icon.sh {tmuxPluginsBattery = pkgs.tmuxPlugins.battery;}} $out/scripts/battery_icon.sh
            cp ${pkgs.replaceVars ./plugins/monitor/scripts/battery_remain.sh {tmuxPluginsBattery = pkgs.tmuxPlugins.battery;}} $out/scripts/battery_remain.sh

            chmod +x $out/scripts/*.sh
            chmod +x $out/monitor.tmux
          '';
        };

        # Tmux configuration - use replaceVars for clean variable replacement
        tmuxConfig = pkgs.runCommand "tmux.conf" {} ''
          cp ${pkgs.replaceVars ./tmux.conf.in {
            tmuxBin = pkgs.tmux;
            tmuxPluginsCopycat = pkgs.tmuxPlugins.copycat;
            tmuxPluginsPainControl = pkgs.tmuxPlugins.pain-control;
            tmuxPluginsYank = pkgs.tmuxPlugins.yank;
            tmuxCatppuccin = tmux-catppuccin;
            tmuxPluginsBattery = pkgs.tmuxPlugins.battery;
            tmuxMonitor = tmux-monitor;
          }} $out
        '';

        # Wrapper script that runs tmux with Nix-managed config (non-destructive)
        tmuxWrapper = pkgs.writeShellScriptBin "tmux" ''
          export TMUX_CONFIG_PATH="${tmuxConfig}"
          export PATH="${pkgs.tmux}/bin:$PATH"

          exec ${pkgs.tmux}/bin/tmux -f ${tmuxConfig} "$@"
        '';
      in {
        packages = {
          default = tmuxWrapper;
          tmux = tmuxWrapper;
          tmux-unwrapped = pkgs.tmux;
        };

        apps = {
          default = {
            type = "app";
            program = "${tmuxWrapper}/bin/tmux";
          };
          tmux = {
            type = "app";
            program = "${tmuxWrapper}/bin/tmux";
          };
        };

        # Development shell with tmux available
        devShells.default = pkgs.mkShellNoCC {
          packages = [tmuxWrapper];
          shellHook = ''
            echo "Portable tmux with custom configuration available!"
            echo "Run 'tmux' to start a session with full monitoring and theming."
          '';
        };
      };
    };
}
