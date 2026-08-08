# home-manager module: installs astropath as a DankMaterialShell plugin.
#
# Assembles the plugin (plugin.json + src/) into the store and links it into DMS's plugin
# folder. Enabling it then happens inside DMS (Settings → Plugins → Astropath).
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
    lib.mkEnableOption "astropath — notmuch mail widget for DankMaterialShell";

  config = lib.mkIf cfg.enable {
    # DMS discovers the plugin in ~/.config/DankMaterialShell/plugins/.
    xdg.configFile."DankMaterialShell/plugins/Astropath".source = plugin;

    # notmuch is required at runtime (the widget executes it).
    home.packages = [pkgs.notmuch];
  };
}
