{ config, pkgs, inputs, lib, modulesPath, age, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../../profiles/global
    ../../profiles/systemd-boot.nix
    ../../users/simonwjackson/default.nix
    ./services/tandoor.nix
    ./services/paperless-ngx.nix
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/e7992d4c-23f6-453e-99b8-b68a717a6156";
    fsType = "btrfs";
    options = [ "subvol=root" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/e7992d4c-23f6-453e-99b8-b68a717a6156";
    fsType = "btrfs";
    options = [ "subvol=home" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/e7992d4c-23f6-453e-99b8-b68a717a6156";
    fsType = "btrfs";
    options = [ "subvol=nix" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/A777-1B40";
    fsType = "vfat";
  };

  fileSystems."/glacier/iceberg" = {
    device = "/dev/disk/by-label/iceberg";
    fsType = "btrfs";
    options = [ "compress=zstd" "noatime" "autodefrag" "space_cache=v2" ];
  };

  systemd.services.mountSnowscape = {
    script = ''
      install -d -o simonwjackson -g users -m 770 /glacier/snowscape
      ${pkgs.util-linux}/bin/mountpoint -q /glacier/snowscape || ${pkgs.mount}/bin/mount -t bcachefs /dev/disk/by-id/nvme-SAMSUNG_MZQLB7T6HMLA-00007_S4BGNC0RA01126_1-part1:/dev/disk/by-id/nvme-SAMSUNG_MZQLB7T6HMLA-00007_S4BGNC0R803650_1-part1:/dev/disk/by-id/ata-WDC_WD80EFAX-68LHPN0_7SGKDA3C-part1:/dev/disk/by-id/ata-WDC_WD80EFBX-68AZZN0_VRJVWS3K-part1:/dev/disk/by-id/ata-WDC_WD80EDAZ-11TA3A0_VGH3KRAG-part1:/dev/disk/by-id/ata-WDC_WD80EDAZ-11TA3A0_VGH13XMG-part1:/dev/disk/by-partuuid/4c63c6a0-ca41-e64f-bf66-1b8ea170e5f9:/dev/disk/by-partuuid/a65978da-998d-db4c-aaef-d7e3321d11c3:/dev/disk/by-partuuid/99bd5d36-9353-4754-837b-008e0d92fe28:/dev/disk/by-partuuid/1627228d-5821-3a40-8e29-0d48928b5852 /glacier/snowscape
    '';
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
    };
  };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # hardware.opengl.enable = true;
  # services.xserver.videoDrivers = [ "nvidia" ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.supportedFilesystems = [ "bcachefs" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable the Plasma 5 Desktop Environment.
  services.xserver.desktopManager.plasma5.enable = true;

  services.xserver.displayManager = {
    sddm.enable = true;
    autoLogin.enable = true;
    autoLogin.user = "simonwjackson";
  };

  networking.hostName = "unzen"; # Define your hostname.

  # Enable the X11 windowing system.
  services.xserver.enable = true;


  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.simonwjackson = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      mpv
      neovim
      tmux
      kitty
      git
      firefox
      btop

      yuzu
      cemu
      retroarchFull
      dolphinEmu
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  services.flatpak.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-kde
    ];
  };

  hardware.bluetooth.enable = true;

  systemd.services.ensureNfsRoot = {
    script = ''
      install -d -o nobody -g nogroup -m 770 /export
    '';
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
    };
  };

  fileSystems."/export/snowscape" = {
    device = "/glacier/snowscape";
    options = [ "bind" ];
  };

  fileSystems."/home/simonwjackson/code" = {
    device = "/glacier/snowscape/code";
    options = [ "bind" ];
  };

  services.nfs.server = {
    enable = true;
    exports = ''
      /export		192.18.0.0/16(rw,fsid=0,no_subtree_check,crossmnt)	100.0.0.0/8(rw,fsid=0,no_subtree_check,crossmnt)
      /export/snowscape	192.18.0.0/16(fsid=1,insecure,rw,sync,no_subtree_check)	100.0.0.0/8(fsid=1,insecure,rw,sync,no_subtree_check)
    '';
  };

  services.samba-wsdd.enable = true; # make shares visible for windows 10 clients
  services.samba = {
    enable = true;
    securityType = "user";
    extraConfig = ''
      workgroup = WORKGROUP
      server string = smbnix
      netbios name = smbnix
      security = user
      #use sendfile = yes
      #max protocol = smb2
      # note: localhost is the ipv6 localhost ::1
      hosts allow = 100. 192.18. 10.147.19. 127.0.0.1 localhost
      hosts deny = 0.0.0.0/0
      guest account = nobody
      map to guest = bad user
      acl allow execute always = True
    '';
    shares = {
      snowscape = {
        path = "/glacier/snowscape";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "simonwjackson";
        "force group" = "users";
      };
    };
  };

  services.borgbackup.jobs = {
    taskwarrior = {
      paths = "/home/simonwjackson/.local/share/task";
      repo = "/glacier/iceberg/permafrost/taskwarrior";
      encryption.mode = "none";
      compression = "zstd,22";
      startAt = "hourly";
      prune = {
        keep = {
          within = "7d";
        };
      };
    };

    gaming-profiles = {
      paths = "/glacier/snowscape/gaming/profiles";
      repo = "/glacier/iceberg/permafrost/gaming/profiles";
      encryption.mode = "none";
      compression = "zstd,22";
      startAt = "daily"; # every day
      exclude = [ ];
      prune = {
        keep = {
          within = "30d";
        };
      };
    };

    photos = {
      paths = "/glacier/snowscape/photos";
      repo = "/glacier/iceberg/permafrost/photos";
      encryption.mode = "none";
      compression = "zstd,22";
      startAt = "daily"; # every day
    };

    notes = {
      paths = "/glacier/snowscape/documents/notes";
      repo = "/glacier/iceberg/permafrost/notes";
      encryption.mode = "none";
      startAt = "daily"; # every day
      prune = {
        keep = {
          within = "30d";
        };
      };
    };
  };

  # services.syncthing = {
  #   dataDir = "/home/simonwjackson"; # Default folder for new synced folders
  #
  #   folders = {
  #     code.path = "/home/simonwjackson/code";
  #     documents.path = "/glacier/snowscape/documents";
  #     gaming-games.path = "/glacier/snowscape/gaming/games";
  #     gaming-launchers.path = "/glacier/snowscape/gaming/launchers";
  #     gaming-profiles.path = "/glacier/snowscape/gaming/profiles";
  #     gaming-systems.path = "/glacier/snowscape/gaming/systems";
  #     taskwarrior.path = "/home/simonwjackson/.local/share/task";
  #                                                                                                  
  #     code.devices = [ "fiji" "unzen" "zao" ];
  #     documents.devices = [ "fiji" "usu" "unzen" "yari" "zao" ];
  #     gaming-games.devices = [ "fiji" "unzen" "yari" "zao" ];
  #     gaming-launchers.devices = [ "fiji" "unzen" "zao" ];
  #     gaming-profiles.devices = [ "fiji" "usu" "unzen" "yari" "zao" ];
  #     gaming-systems.devices = [ "fiji" "unzen" "zao" ];
  #     taskwarrior.devices = [ "fiji" "unzen" "zao" ];
  #
  #     gaming-profiles.versioning = {
  #       type = "staggered";
  #       params = {
  #         cleanInterval = "3600";
  #         maxAge = "31536000";
  #       };
  #     };
  #   };
  # };

  # TODO: Add this to general networking config
  # WARN: This speeds up `nixos-rebuild`, but im not sure if there are any side effects
  systemd.services.NetworkManager-wait-online.enable = false;


  services.printing.enable = true;
  services.printing.drivers = with pkgs; [ brlaser ];

  # Enable automatic discovery of the printer from other Linux systems with avahi running.
  services.avahi.enable = true;
  services.avahi.publish.enable = true;
  services.avahi.publish.userServices = true;
  services.printing.browsing = true;
  services.printing.listenAddresses = [ "*:631" ]; # Not 100% sure this is needed and you might want to restrict to the local network
  services.printing.allowFrom = [ "all" ]; # this gives access to anyone on the interface you might want to limit it see the official documentation
  services.printing.defaultShared = true; # If you want

  networking.firewall.allowedUDPPorts = [ 631 ];
  networking.firewall.allowedTCPPorts = [ 631 ];
}