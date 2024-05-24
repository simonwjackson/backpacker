{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.backpacker) enabled;

  cfg = config.backpacker.profiles.laptop;
in {
  options.backpacker.profiles.laptop = {
    enable = lib.mkEnableOption "Whether to enable laptop configurations";
  };

  config = lib.mkIf cfg.enable {
    backpacker = {
      hardware = {
        touchpad = enabled;
        battery = enabled;
        hybrid-sleep = enabled;
      };
    };

    environment.systemPackages = with pkgs; [
      acpi
    ];
  };
}
