{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.backpacker) enabled;

  cfg = config.backpacker.hardware.touchpad;
in {
  options.backpacker.hardware.touchpad = {
    enable = lib.mkEnableOption "Whether to enable touchpad configs";
  };

  config = lib.mkIf cfg.enable {
    services.libinput.enable = true;
    services.libinput.touchpad.disableWhileTyping = true;
    services.libinput.touchpad.tapping = true;
  };
}
