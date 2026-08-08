{
  description = ''
    astropath — Quickshell / DankMaterialShell mail widget.
    Mail-at-a-glance over a notmuch-indexed Maildir, reasoning by thread
    and by tag. Reading in alot, syncing with offlineimap + imapnotify.
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      # home-manager module: installs astropath as a DankMaterialShell plugin.
      flake.homeModules.default = import ./nix/hm-module.nix;

      perSystem = {pkgs, ...}: let
        # Isolated DMS instance launcher, to test the worktree (see scripts/astropath-dev).
        astropath-dev = pkgs.writeShellApplication {
          name = "astropath-dev";
          runtimeInputs = [pkgs.jq];
          text = builtins.readFile ./scripts/astropath-dev;
        };
      in {
        formatter = pkgs.alejandra;

        packages.dev-bar = astropath-dev;
        apps.dev-bar = {
          type = "app";
          program = "${astropath-dev}/bin/astropath-dev";
        };

        devShells.default = pkgs.mkShell {
          name = "astropath";
          packages = with pkgs; [
            # Runtime / target
            quickshell
            qt6.qtdeclarative # qmllint, qmlformat, qmltestrunner
            qt6.qtbase

            # Data engine
            notmuch

            # Project tooling
            just
            git
            git-cliff
            jq # scripts/astropath-dev (isolated dev instance)

            # Nix gates (see .pre-commit-config.yaml)
            alejandra
            deadnix
          ];

          shellHook = ''
            echo ""
            echo "  astropath — mail widget for Quickshell / DankMaterialShell"
            echo "  quickshell · notmuch · qmllint/qmlformat ready."
            echo "  just ci"
            echo ""
          '';
        };
      };
    };
}
