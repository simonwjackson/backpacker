# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ 
    <nixos-hardware/dell/xps/17-9700/nvidia>
    (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "usbhid" "sd_mod"
  # "rtsx_pci_sdmmc"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [
    "kvm-intel"
    "uinput"
  ];
  boot.extraModulePackages = [ ];
  boot.kernelPackages = pkgs.linuxPackages_zen;
  # boot.extraModulePackages = [
  #   config.boot.kernelPackages.rtl88x2bu
  #   config.boot.kernelPackages.rtl8814au
  # ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/015bf7c2-0912-4d69-8e08-8e18d1ac287a";
      fsType = "btrfs";
      options = [ "subvol=root" "compress=zstd" ];
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/015bf7c2-0912-4d69-8e08-8e18d1ac287a";
      fsType = "btrfs";
      options = [ "subvol=home" "compress=zstd" ];
    };

  fileSystems."/storage" =
    { device = "/dev/disk/by-uuid/015bf7c2-0912-4d69-8e08-8e18d1ac287a";
      fsType = "btrfs";
      options = [ "subvol=storage" "compress=zstd" ];
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/015bf7c2-0912-4d69-8e08-8e18d1ac287a";
      fsType = "btrfs";
      options = [ "subvol=nix" "compress=zstd" "noatime" ];
    };

  fileSystems."/sdcard" = {
    device = "/dev/mmcblk0";
    fsType = "f2fs"; 
    options = [
      "compress_algorithm=zstd:6"
      "compress_chksum"
      "atgc"
      "gc_merge"
      "lazytime"
    ];
  };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/D21E-0411";
      fsType = "vfat";
    };

  swapDevices = [ { device = "/dev/nvme0n1p2"; } ];

  # Includes the Wi-Fi and Bluetooth firmware
  hardware.enableRedistributableFirmware = true;

  hardware.opengl.enable = true;
  hardware.nvidia.prime.offload.enable = lib.mkForce true;
  services.xserver.videoDrivers = [ "nvidia" ];

  # Optionally, you may need to select the appropriate driver version for your specific GPU.
  # hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.production;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  networking.useDHCP = lib.mkDefault true;
}
