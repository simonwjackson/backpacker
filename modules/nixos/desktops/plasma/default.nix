{
  config,
  lib,
  ...
}: let
  inherit (lib.backpacker) enabled;
  cfg = config.backpacker.desktops.plasma;
in {
  options.backpacker.desktops.plasma = {
    enable = lib.mkEnableOption "Whether to enable the plasma desktop";
    autoLogin = lib.mkEnableOption "Whether to auto login to the plasma desktop";
  };

  config = lib.mkIf cfg.enable {
    xdg.portal = enabled;
    programs.xwayland = enabled;

    services = {
      desktopManager.plasma6 = enabled;

      xserver = enabled;

      displayManager.sddm.wayland = enabled;
      displayManager.sddm.enable = true;
      displayManager.defaultSession = lib.mkIf cfg.autoLogin "plasma";
      displayManager.autoLogin = lib.mkIf cfg.autoLogin {
        enable = true;
        user = config.backpacker.user.name;
      };
    };

    environment.sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
    };
  };
}
