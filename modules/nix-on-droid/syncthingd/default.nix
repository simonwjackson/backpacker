{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.syncthingd;

  service = pkgs.writeScript "start-syncthing" ''
    #!/usr/bin/env bash

    if ! ${pkgs.procps}/bin/ps aux | ${pkgs.gnugrep}/bin/grep -v grep | ${pkgs.gnugrep}/bin/grep -v $$ | ${pkgs.gnugrep}/bin/grep -q "${pkgs.syncthing}/bin/syncthing"; then
      ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "${cfg.logFile}")"
      nohup ${cfg.package}/bin/syncthing -no-browser -home="${cfg.dataDir}" >> "${cfg.logFile}" 2>&1 &
    fi
  '';
in {
  options.services.syncthingd = {
    enable = lib.mkEnableOption "Syncthing";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.syncthing;
      description = "The Syncthing package to use.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.user.home}/.config/syncthing";
      description = "The path where Syncthing configuration will be stored.";
    };

    logFile = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.dataDir}/syncthing.log";
      description = "The path to the Syncthing log file.";
    };

    keyFile = lib.mkOption {
      type = lib.types.str;
      description = "The path to the Syncthing key file.";
    };

    certFile = lib.mkOption {
      type = lib.types.str;
      description = "The path to the Syncthing certificate file.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.packages = with pkgs; [
      syncthing-cli
    ];

    environment.extraProfile = ["${service}"];

    build.activation.installSyncthingd = ''
      #!/usr/bin/env bash

      $VERBOSE_ECHO "Creating Syncthing data directory"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${cfg.dataDir}"

      $VERBOSE_ECHO "Creating symbolic link for Syncthing key file"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sf "${cfg.keyFile}" "${cfg.dataDir}/key.pem"

      $VERBOSE_ECHO "Creating symbolic link for Syncthing certificate file"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sf "${cfg.certFile}" "${cfg.dataDir}/cert.pem"

      $VERBOSE_ECHO "Syncthing key and certificate symlinks created in ${cfg.dataDir}"
    '';
  };
}
