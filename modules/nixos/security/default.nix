{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkOption;

  cfg = config.backpacker.security;
in {
  options.backpacker.security = {
    enable = mkEnableOption "Whether to enable security";
  };

  config = lib.mkIf cfg.enable {
    security = {
      rtkit.enable = true;

      sudo = {
        wheelNeedsPassword = false;
        extraRules = [
          {
            users = ["${config.backpacker.user.name}"];

            commands = [
              {
                command = "ALL";
                options = ["NOPASSWD" "SETENV"];
              }
            ];
          }
        ];
      };

      # Increase open file limit for sudoers
      pam.loginLimits = [
        {
          domain = "@wheel";
          type = "-";
          item = "memlock";
          value = "unlimited";
        }
        {
          domain = "${config.backpacker.user.name}";
          type = "soft";
          item = "memlock";
          value = "unlimited";
        }
        {
          domain = "${config.backpacker.user.name}";
          type = "hard";
          item = "memlock";
          value = "unlimited";
        }
      ];
    };
  };
}
