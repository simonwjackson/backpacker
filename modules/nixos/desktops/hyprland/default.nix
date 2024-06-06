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

  cfg = config.backpacker.desktops.hyprland;
in {
  options.backpacker.desktops.hyprland = {
    enable = lib.mkEnableOption "Whether to enable the hyprland desktop";

    autoLogin = lib.mkEnableOption "Whether to auto login to the hyprland desktop";
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${system}.hyprland;
    };

    xdg.portal = enabled;
    programs.xwayland = enabled;

    services = {
      xserver = {
        enable = true;
        desktopManager.plasma5 = enabled;
      };

      displayManager =
        {
          sddm = {
            enable = true;
            wayland.enable = true;
          };
        }
        // lib.mkIf cfg.autoLogin {
          defaultSession = "hyprland";
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
