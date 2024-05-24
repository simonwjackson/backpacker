{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption;

  cfg = config.backpacker.direnv;
in {
  options.backpacker.direnv = {
    enable = mkEnableOption "Whether to enable direnv";
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = config.programs.zsh.enable;
      enableBashIntegration = config.programs.bash.enable;
      # TODO: check for tank here
      # config = ''
      #   [whitelist]
      #   prefix = [ "/home/simonwjackson/code" ]
      # '';
    };
  };
}
