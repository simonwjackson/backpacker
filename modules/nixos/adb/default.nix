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
  };

  config = mkIf cfg.enable {
    programs.adb.enable = true;
    users.users."${config.backpacker.user.name}".extraGroups = ["adbusers"];
    services.udev.packages = [
      pkgs.android-udev-rules
    ];
  };
}
