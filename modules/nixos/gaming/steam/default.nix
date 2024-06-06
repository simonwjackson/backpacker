{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}: let
  cfg = config.backpacker.gaming.steam;
  steamAppsOverlay = "/home/${config.backpacker.user.name}/.var/app/com.valvesoftware.Steam/data/Steam/steamapps";
  mountpoint = "${pkgs.util-linux}/bin/mountpoint";
  mount = "${pkgs.mount}/bin/mount";
in {
  options.backpacker.gaming.steam = {
    enable = lib.mkEnableOption "Enable steam";
    steamApps = lib.mkOption {
      type = lib.types.path;
      # steamApps = "${snowscape}/gaming/games/steam/steamapps";
      description = "";
    };
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-kde
      ];
    };
    services.flatpak.remotes = lib.mkOptionDefault [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];
    services.flatpak.packages = [
      "com.valvesoftware.Steam"
      "com.valvesoftware.Steam.CompatibilityTool.Proton-GE"
      "org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/23.08"
      "org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/23.08"
    ];

    systemd.services.mountSteamAppsOverlay = {
      # after = ["mountSnowscape.service"];
      script = ''
        install -d -o ${config.backpacker.user.name} -g users -m 770 ${cfg.steamApps}
        install -d -o ${config.backpacker.user.name} -g users -m 770 /home/${config.backpacker.user.name}/.var/app/com.valvesoftware.Steam/data/Steam/steamapps
        ${mountpoint} -q ${steamAppsOverlay} || ${mount} --bind ${cfg.steamApps} ${steamAppsOverlay}
      '';
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
      };
    };
  };
}
