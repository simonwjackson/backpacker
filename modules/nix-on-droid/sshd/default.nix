{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types mkIf hm;
  cfg = config.services.sshd;

  startSshdScript = pkgs.writeScript "start-sshd" ''
    #!/usr/bin/env bash

    if ! ${pkgs.procps}/bin/ps aux | ${pkgs.gnugrep}/bin/grep -v grep | ${pkgs.gnugrep}/bin/grep -v $$ | ${pkgs.gnugrep}/bin/grep -q "${pkgs.openssh}/bin/sshd"; then
      ${pkgs.openssh}/bin/sshd -f /etc/ssh/sshd_config -E /tmp/sshd.log
    fi
  '';
in {
  options.services.sshd = {
    enable = mkEnableOption "SSHD Service for Nix-on-Droid";

    port = mkOption {
      type = types.port;
      default = 8022;
      description = "Port on which sshd should listen";
    };

    authorizedKeys = mkOption {
      type = types.lines;
      default = "";
      description = "Authorized public keys for SSH access";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra lines to be added to sshd_config";
    };
  };

  config = mkIf cfg.enable {
    environment.packages = with pkgs; [
      pkgs.openssh
    ];

    environment.etc."ssh/authorized_keys".text = cfg.authorizedKeys;

    environment.etc."ssh/sshd_config".text = ''
      HostKey /etc/ssh/ssh_host_rsa_key
      Port ${toString cfg.port}
      PermitRootLogin no
      PubkeyAuthentication yes
      PasswordAuthentication no
      ChallengeResponseAuthentication no
      UsePAM no
      PrintMotd no
      AcceptEnv LANG LC_*
      AuthorizedKeysFile /etc/ssh/authorized_keys

      ${cfg.extraConfig}
    '';

    environment.extraProfile = ["${startSshdScript}"];

    build.activation.setupSshdScript = ''
      #!/usr/bin/env bash

      $DRY_RUN_CMD mkdir -p /etc/ssh

      # Generate SSH host key if it doesn't exist
      if [ ! -f "/etc/ssh/ssh_host_rsa_key" ]; then
        $DRY_RUN_CMD ${pkgs.openssh}/bin/ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
      fi
    '';
  };
}
