{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}: let
  inherit (lib) mkEnableOption mkOption;

  cfg = config.backpacker.gaming.emulation;
  share = "/home/${config.backpacker.user.name}/.local/share";
in {
  options.backpacker.gaming.emulation = {
    enable = mkEnableOption "Whether to enable emulation";
    gen-8 = mkEnableOption "Whether to enable the 8th generation of consoles";
    gen-7 = mkEnableOption "Whether to enable the 7th generation of consoles";
    # gamingDir = mkOption {
    #   type = lib.types.path;
    # };
    saves = mkOption {
      type = lib.types.path;
      default = config.backpacker.user.home;
      description = "Container directory for game saves";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = let
      gen-7 = [
        pkgs.dolphinEmu
        pkgs.rpcs3
      ];
      gen-8 = [
        pkgs.cemu
        inputs.suyu.packages."${system}".suyu
      ];
    in
      [
        pkgs.retroarchFull
      ]
      ++ lib.optionals cfg.gen-8 gen-7
      ++ lib.optionals cfg.gen-8 gen-8;

    # BUG: if dirs dont exist, they are owned by root
    fileSystems = {
      "${share}/dolphin-emu/GC" = {
        device = "${cfg.saves}/nintendo-gamecube/";
        options = ["bind"];
      };

      "${share}/dolphin-emu/Wii/title" = {
        device = "${cfg.saves}/nintendo-wii/";
        options = ["bind"];
      };

      "${share}/Cemu/mlc01/usr" = {
        device = "${cfg.saves}/nintendo-wiiu/";
        options = ["bind"];
      };

      # "${share}/yuzu/sdmc" = {
      #   device = "${cfg.saves}/nintendo-switch/sdmc";
      #   options = ["bind"];
      # };
      #
      # "${share}/yuzu/shader" = {
      #   device = "${cfg.gamingDir}/launchers/yuzu/shader";
      #   options = ["bind"];
      # };
      #
      # "${share}/yuzu/keys" = {
      #   device = "${cfg.gamingDir}/systems/nintendo-switch/keys";
      #   options = ["bind"];
      # };
      #
      # "${share}/yuzu/nand" = {
      #   device = "${cfg.saves}/nintendo-switch/nand";
      #   options = ["bind"];
      # };
    };
  };
}
