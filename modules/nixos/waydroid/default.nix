{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkOption;
  inherit (lib.backpacker) enabled;

  cfg = config.backpacker.waydriod;
in {
  options.backpacker.waydriod = {
    enable = mkEnableOption "Whether to enable waydriod";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.waydroid = enabled;
  };
}
