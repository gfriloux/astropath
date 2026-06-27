{
  description = ''
    astropath — widget mail Quickshell / DankMaterialShell.
    Visu rapide des mails indexés par notmuch (Maildir), raisonnement
    par fil et par tag. Lecture dans alot, synchro offlineimap + imapnotify.
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

      # Module home-manager : installe astropath comme plugin DankMaterialShell.
      flake.homeModules.default = import ./nix/hm-module.nix;

      perSystem = {pkgs, ...}: let
        # Launcher d'instance DMS isolée pour tester le worktree (cf. scripts/astropath-dev).
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
            # Runtime / cible
            quickshell
            qt6.qtdeclarative # qmllint, qmlformat, qmltestrunner
            qt6.qtbase

            # Moteur de données
            notmuch

            # Outillage projet
            just
            git
            git-cliff
            jq # scripts/astropath-dev (instance dev isolée)

            # Portes Nix (cf. .pre-commit-config.yaml)
            alejandra
            deadnix
          ];

          shellHook = ''
            echo ""
            echo "  astropath — mail widget pour Quickshell / DankMaterialShell"
            echo "  quickshell · notmuch · qmllint/qmlformat prêts."
            echo "  just ci"
            echo ""
          '';
        };
      };
    };
}
