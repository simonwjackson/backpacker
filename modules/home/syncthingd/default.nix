{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.syncthingd;

  serviceFile = "${config.home.homeDirectory}/.local/bin/start-syncthing.sh";
  service = ''
    #!/usr/bin/env bash

    if ! ${pkgs.procps}/bin/ps aux | ${pkgs.gnugrep}/bin/grep -v grep | ${pkgs.gnugrep}/bin/grep -v $$ | ${pkgs.gnugrep}/bin/grep -q "${serviceFile}"; then
      mkdir -p "$(dirname "${cfg.logFile}")"

      nohup ${cfg.package}/bin/syncthing -no-browser -home="${cfg.homePath}" >> "${cfg.logFile}" 2>&1 &
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

    homePath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.config/syncthing";
      description = "The path where Syncthing configuration will be stored.";
    };

    logFile = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.homePath}/syncthing.log";
      description = "The path to the Syncthing log file.";
    };

    # keyFile = lib.mkOption {
    #   type = lib.types.str;
    #   description = "The path to the Syncthing key file.";
    # };
    #
    # certFile = lib.mkOption {
    #   type = lib.types.str;
    #   description = "The path to the Syncthing certificate file.";
    # };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];

    home.file."${serviceFile}" = {
      executable = true;
      text = service;
    };

    programs.bash.initExtra = serviceFile;

    # home.file."${cfg.homePath}/key.pem".source = config.lib.file.mkOutOfStoreSymlink cfg.keyFile;
    # home.file."${cfg.homePath}/cert.pem".source = config.lib.file.mkOutOfStoreSymlink cfg.certFile;
  };
}
