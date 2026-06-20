# Module home-manager : installe astropath comme plugin DankMaterialShell.
#
# Assemble le plugin (plugin.json + src/) dans le store et le lie dans le dossier de
# plugins de DMS. L'activation se fait ensuite dans DMS (Settings → Plugins → Astropath).
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.astropath;

  plugin = pkgs.runCommandLocal "astropath-plugin" {} ''
    mkdir -p $out
    cp ${../plugin.json} $out/plugin.json
    cp -r ${../src} $out/src
  '';
in {
  options.programs.astropath.enable =
    lib.mkEnableOption "astropath — widget mail notmuch pour DankMaterialShell";

  config = lib.mkIf cfg.enable {
    # Le plugin est découvert par DMS dans ~/.config/DankMaterialShell/plugins/.
    xdg.configFile."DankMaterialShell/plugins/Astropath".source = plugin;

    # notmuch est requis au runtime (le widget l'exécute).
    home.packages = [pkgs.notmuch];
  };
}
