{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.backpacker.adb;
in {
  options.backpacker.adb = {
    enable = mkEnableOption "Whether to enable adb tooling";

    user = lib.mkOption {
      type = lib.types.str;
      default = config.backpacker.user.name;
      description = "";
    };
  };

  config = mkIf cfg.enable {
    programs.adb.enable = true;
    users.users."${cfg.user}".extraGroups = ["adbusers"];
    services.udev.packages = [
      pkgs.android-udev-rules
    ];
  };
}
