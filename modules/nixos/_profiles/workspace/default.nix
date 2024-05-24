{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkDefault;
  inherit (lib.backpacker) enabled;

  cfg = config.backpacker.profiles.workspace;
in {
  options.backpacker.profiles.workspace = {
    enable = mkEnableOption "Whether to enable workspace configurations";
  };

  config = lib.mkIf cfg.enable {
    backpacker = {
      adb = mkDefault enabled;
    };

    services = {
      xserver.enable = true;
      displayManager = {
        autoLogin.user = config.backpacker.user.name;
        defaultSession = "home-manager";
      };

      # NOTE: We need to create at least one session for auto login to work
      xserver.desktopManager.session = [
        {
          name = "home-manager";
          start = ''
            ${pkgs.runtimeShell} $HOME/.hm-xsession &
            waitPID=$!
          '';
        }
      ];
    };

    programs.dconf.enable = true;

    xdg.portal = {
      enable = true;

      extraPortals = with pkgs; [
        xdg-desktop-portal-kde
      ];
    };
  };
}
