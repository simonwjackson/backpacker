{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types mkIf;

  cfg = config.services.virtualGamepadProxy;
  pythonWithPackages = pkgs.python3.withPackages (ps: with ps; [evdev]);
in {
  options.services.virtualGamepadProxy = {
    enable = mkEnableOption "Virtual Gamepad Proxy service";

    user = mkOption {
      type = types.str;
      default = "root";
      description = "User under which the service will run";
    };

    group = mkOption {
      type = types.str;
      default = "root";
      description = "Group under which the service will run";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.virtualGamepadProxy = {
      description = "Virtual Gamepad Proxy Service";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];

      serviceConfig = {
        ExecStart = "${pkgs.writeScriptBin "virtualGamepad" ''
          #!${pythonWithPackages}/bin/python3
          ${builtins.readFile ./virtualGamepad.py}
        ''}/bin/virtualGamepad";
        User = cfg.user;
        Group = cfg.group;
        Restart = "on-failure";
        RestartSec = "5s";
        StandardOutput = "journal+console";
        StandardError = "journal+console";
      };
    };

    users.users.${cfg.user}.extraGroups = ["input"];
  };
}
