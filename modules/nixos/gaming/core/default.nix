{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}: let
  cfg = config.backpacker.gaming.core;
  flatpak = lib.getExe pkgs.flatpak;
in {
  options.backpacker.gaming.core = {
    enable = lib.mkEnableOption "Enable gaming";
    isHost = lib.mkEnableOption "Whether or not device will be used for game streaming";
  };

  config = lib.mkIf cfg.enable {
    # services.input-remapper.enable = false;
    environment.systemPackages = [
      pkgs.antimicrox
      pkgs.moonlight-qt
    ];

    services.udev.extraRules = ''
      SUBSYSTEM=="misc", KERNEL=="uinput", OPTIONS+="static_node=uinput", TAG+="uaccess"
    '';
    # services.flatpak.packages = [
    #   "io.github.antimicrox.antimicrox"
    # ];

    # Switch controllers
    services.joycond.enable = true;

    # backpacker.gaming.sunshine.enable = cfg.isHost;
    # systemd.user.services.startSteam = lib.mkIf (cfg.isHost) {
    #   path = [pkgs.flatpak];
    #   description = "Start Steam Flatpak app";
    #   wantedBy = ["graphical-session.target"];
    #   partOf = ["graphical-session.target"];
    #   after = ["mountSteamAppsOverlay.service"];
    #   serviceConfig = {
    #     ExecStart = "${flatpak} run com.valvesoftware.Steam -forcedesktopscaling=1.5 -silent";
    #     Restart = "on-failure";
    #   };
    # };
  };
}
