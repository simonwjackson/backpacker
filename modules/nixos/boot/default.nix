{
  config,
  lib,
  pkgs,
  ...
}: {
  options.mountainous.boot = {
    type = lib.mkOption {
      type = with lib.types; enum ["bios" "uefi" "lanzaboote"];
      default = "uefi";
      description = ''
        What type of bootloader module to use.
      '';
    };

    # Whether to enable Plymouth and reduce TTY verbosity.
    quiet = lib.mkOption {
      type = with lib.types; bool;
      default = false;
    };
  };

  config = let
    inherit (config.mountainous.boot) type quiet;
    # inherit (config.networking) hostName;
  in
    lib.mkMerge [
      # BIOS:
      (lib.mkIf (type == "bios") {
        boot.loader.grub.efiSupport = false;
      })

      # UEFI: common options.
      (lib.mkIf (type == "uefi" || type == "lanzaboote") {
        boot.loader.efi.canTouchEfiVariables = true;
      })

      # UEFI: GRUB2 non-secure boot.
      (lib.mkIf (type == "uefi") {
        boot.loader = {
          systemd-boot = {
            enable = true;
            consoleMode = "max";
          };
        };
      })

      # Quiet boot with minimal logging.
      (lib.mkIf quiet {
        boot = {
          plymouth = {
            enable = true;
            theme = "breeze";

            # WARN: Build sometimes fails with this uncommented for some reason.
            logo = ./saturn-128x.png;
            font = let
              dir = "share/fonts/truetype/NerdFonts";
              font = pkgs.nerdfonts.override {
                fonts = ["BigBlueTerminal"];
              };
            in "${font}/${dir}/BigBlueTermPlusNerdFont-Regular.ttf";
          };

          consoleLogLevel = 0;
          kernelParams = [
            "quiet"
            "loglevel=3"
            "systemd.show_status=auto"
            "udev.log_level=3"
            "rd.udev.log_level=3"
            "vt.global_cursor_default=0"
          ];

          initrd = {
            systemd.enable = true;
            verbose = false;
          };
        };
      })
    ];
}