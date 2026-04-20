{
  description = "Pinned versions of nixpkgs (unstable and stable) for use across multiple projects";
  inputs = {
    unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    stable.url = "github:nixos/nixpkgs/release-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      flake.overlays.default = final: prev: {
        nushell = prev.nushell.overrideAttrs (oldAttrs: {
          checkPhase = let
            # The skipped tests all fail in the sandbox because in the nushell test playground,
            # the tmp $HOME is not set, so nu falls back to looking up the passwd dir of the build
            # user (/var/empty). The assertions however do respect the set $HOME.
            skippedTests =
              [
                "repl::test_config_path::test_default_config_path"
                "repl::test_config_path::test_xdg_config_bad"
                "repl::test_config_path::test_xdg_config_empty"
              ]
              ++ prev.lib.optionals prev.stdenv.hostPlatform.isDarwin [
                "plugins::config::some"
                "plugins::stress_internals::test_exit_early_local_socket"
                "plugins::stress_internals::test_failing_local_socket_fallback"
                "plugins::stress_internals::test_local_socket"

                # Error:   × I/O error: Operation not permitted (os error 1)
                "shell::environment::env::env_shlvl_in_exec_repl"
                "shell::environment::env::env_shlvl_in_repl"
                "shell::environment::env::path_is_a_list_in_repl"
              ];

            skippedTestsStr = prev.lib.concatStringsSep " " (prev.lib.map (testId: "--skip=${testId}") skippedTests);
          in ''
            runHook preCheck

            cargo test -j $NIX_BUILD_CORES --offline -- \
              --test-threads=$NIX_BUILD_CORES ${skippedTestsStr}

            runHook postCheck
          '';
        });
      };

      perSystem = {system, ...}: let
        pkgs = import inputs.unstable {
          inherit system;
          config = {allowUnfree = true;};
          overlays = [inputs.self.overlays.default];
        };
      in {
        formatter = pkgs.alejandra;
        legacyPackages = pkgs;
        packages.nushell = pkgs.nushell;
      };
    };
}
