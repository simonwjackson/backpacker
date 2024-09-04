{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}: let
  cfg = config.backpacker.gaming.steam;
  # steamAppsOverlay = "/home/${config.backpacker.user.name}/.var/app/com.valvesoftware.Steam/data/Steam/steamapps";
  # mountpoint = "${pkgs.util-linux}/bin/mountpoint";
  # mount = "${pkgs.mount}/bin/mount";
in {
  imports = [
    inputs.chaotic.nixosModules.default
  ];

  options.backpacker.gaming.steam = {
    enable = lib.mkEnableOption "Enable steam";
    # steamApps = lib.mkOption {
    #   type = lib.types.path;
    #   description = "";
    # };
  };

  config = lib.mkIf cfg.enable {
    # chaotic.appmenu-gtk3-module.enable = true;
    chaotic.mesa-git.enable = true;
    chaotic.mesa-git.fallbackSpecialisation = true;
    chaotic.steam.extraCompatPackages = with pkgs; [
      # proton-ge-custom
      # gamescope
      # mangohud
    ];

    hardware = {
      steam-hardware.enable = true;
    };

    programs = {
      steam = {
        enable = true;
        remotePlay.openFirewall = true;
      };
    };

    nixpkgs = {
      overlays = [
        inputs.chaotic.overlays.default
      ];

      config = {
        steam = pkgs.steam.override {
          extraPkgs = pkgs:
            with pkgs; [
              gamescope-wsi_git
              gamescope_git
              # stable.gamescope
              xorg.libXcursor
              xorg.libXi
              xorg.libXinerama
              xorg.libXScrnSaver
              libpng
              libpulseaudio
              libvorbis
              stdenv.cc.cc.lib
              libkrb5
              keyutils
              mangohud
            ];
        };
        allowUnfree = true;
        permittedInsecurePackages = ["python-2.7.18.6"];
      };
    };

    # environment.systemPackages = [
    #   pkgs.antimicrox
    # ];

    # services.udev.extraRules = ''
    #   SUBSYSTEM=="misc", KERNEL=="uinput", OPTIONS+="static_node=uinput", TAG+="uaccess"
    # '';

    # services.flatpak.enable = true;
    # xdg.portal = {
    #   enable = true;
    #   extraPortals = with pkgs; [
    #     xdg-desktop-portal-kde
    #   ];
    # };
    # services.flatpak.remotes = lib.mkOptionDefault [
    #   {
    #     name = "flathub";
    #     location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
    #   }
    # ];
    # services.flatpak.packages = [
    #   "com.valvesoftware.Steam"
    #   "com.valvesoftware.Steam.CompatibilityTool.Proton-GE"
    #   "org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/23.08"
    #   "org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/23.08"
    #   "io.github.antimicrox.antimicrox"
    # ];

    # systemd.services.mountSteamAppsOverlay = {
    #   # after = ["mountSnowscape.service"];
    #   script = ''
    #     install -d -o ${config.backpacker.user.name} -g users -m 770 ${cfg.steamApps}
    #     install -d -o ${config.backpacker.user.name} -g users -m 770 /home/${config.backpacker.user.name}/.var/app/com.valvesoftware.Steam/data/Steam/steamapps
    #     ${mountpoint} -q ${steamAppsOverlay} || ${mount} --bind ${cfg.steamApps} ${steamAppsOverlay}
    #   '';
    #   wantedBy = ["multi-user.target"];
    #   serviceConfig = {
    #     Type = "oneshot";
    #   };
    # };
  };
}
