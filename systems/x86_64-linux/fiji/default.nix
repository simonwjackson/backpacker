{
  config,
  inputs,
  lib,
  modulesPath,
  options,
  pkgs,
  ...
}: let
  inherit (lib.mountainous) enabled;
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  age.secrets.game-collection-sync.file = ../../../secrets/game-collection-sync.age;
  age.secrets.fiji-syncthing-key.file = ../../../secrets/fiji-syncthing-key.age;
  age.secrets.fiji-syncthing-cert.file = ../../../secrets/fiji-syncthing-cert.age;

  age = {
    identityPaths =
      options.age.identityPaths.default
      ++ [
        # TODO: Pull this value from somewhere else in the config
        "/home/simonwjackson/.ssh/agenix"
      ];
  };

  mountainous = {
    hardware.devices.samsung-galaxy-book3-360 = enabled;
    performance = enabled;
    profiles.laptop = enabled;
    networking.core.names = [
      {
        name = "wifi";
        mac = "d4:d8:53:90:2b:6c";
      }
    ];
  };

  # DESKTOP
  services = {
    xserver.enable = true;
    displayManager.autoLogin.user = "simonwjackson";
    displayManager.defaultSession = "home-manager";
    # We need to create at least one session for auto login to work
    xserver.desktopManager.session = [
      {
        name = "home-manager";
        start = ''
          ${pkgs.runtimeShell} $HOME/.hm-xsession &
          waitPID=$!
        '';
      }
    ];
  };

  programs.dconf.enable = true;

  xdg.portal = {
    enable = true;

    extraPortals = with pkgs; [
      xdg-desktop-portal-kde
    ];
  };
  # END: DESKTOP

  boot.kernelModules = ["kvm-intel"];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.availableKernelModules = ["xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod"];

  disko.devices.disk.nvme0n1 = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-WDSN740-SDDPNQD-1T00-1004_22501B805583";
    content = {
      type = "table";
      format = "gpt";
      partitions = [
        {
          name = "BOOT";
          start = "0";
          end = "1G";
          fs-type = "vfat";
          bootable = true;
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        }
        {
          name = "swap";
          start = "1G";
          end = "17G";
          part-type = "primary";
          content = {
            type = "swap";
            randomEncryption = true;
          };
        }
        {
          name = "root";
          start = "17G";
          end = "145G";
          part-type = "primary";
          content = {
            type = "btrfs";
            subvolumes = {
              "/" = {
                mountpoint = "/";
                mountOptions = ["compress=zstd"];
              };
              "/home" = {
                mountpoint = "/home";
                mountOptions = ["compress=zstd"];
              };
              "/nix" = {
                mountpoint = "/nix";
                mountOptions = ["compress=zstd" "noatime"];
              };
            };
          };
        }
        {
          name = "snowscape";
          start = "145G";
          end = "100%";
          part-type = "primary";
          content = {
            type = "filesystem";
            format = "xfs";
            mountpoint = "/glacier/snowscape";
          };
        }
      ];
    };
  };

  services.syncthing = {
    enable = true;
    key = config.age.secrets.fiji-syncthing-key.path;
    cert = config.age.secrets.fiji-syncthing-cert.path;

    settings.paths = {
      # documents = "/glacier/snowscape/documents";
      notes = "/glacier/snowscape/notes";
      # audiobooks = "/glacier/snowscape/audiobooks";
      # books = "/glacier/snowscape/books";
      # comics = "/glacier/snowscape/comics";
      # code = "/glacier/snowscape/code";
    };
  };

  fileSystems."/home/simonwjackson/documents" = {
    device = "/glacier/snowscape/documents";
    options = ["bind"];
  };

  programs.adb.enable = true;
  users.users.simonwjackson.extraGroups = ["adbusers"];
  services.udev.packages = [
    pkgs.android-udev-rules
  ];

  system.stateVersion = "23.05"; # Did you read the comment?
}
