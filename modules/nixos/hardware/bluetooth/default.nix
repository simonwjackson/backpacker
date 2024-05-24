{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.backpacker.hardware.bluetooth;
in {
  options.backpacker.hardware.bluetooth = {
    enable = mkEnableOption "Whether to enable bluetooth";
  };

  config = mkIf cfg.enable {
    hardware = {
      bluetooth = {
        enable = true;
        powerOnBoot = true; # powers up the default Bluetooth controller on boot
      };
    };

    services.blueman.enable = true;
  };
}
