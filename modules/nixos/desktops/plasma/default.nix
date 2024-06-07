{
  lib,
  pkgs,
  inputs,
  system,
  target,
  format,
  virtual,
  systems,
  config,
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

      xserver = {
        enable = true;
      };

      displayManager =
        {
          sddm = {
            enable = true;
            wayland = enabled;
          };
        }
        // lib.mkIf cfg.autoLogin {
          defaultSession = "plasma";
          autoLogin = {
            enable = true;
            user = config.backpacker.user.name;
          };
        };
    };

    environment.sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
    };
  };
}
