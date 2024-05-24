{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption;

  cfg = config.backpacker.eza;
in {
  options.backpacker.eza = {
    enable = mkEnableOption "Whether to enable eza";
  };

  config = lib.mkIf cfg.enable {
    home.shellAliases = {
      lt = "eza -lT";
      lat = "eza -laT";
      ll = "eza --long --header --git";
      ls = "eza";
      l = "eza -l";
      la = "eza -la";
    };

    home.packages = [
      pkgs.eza
    ];
  };
}
