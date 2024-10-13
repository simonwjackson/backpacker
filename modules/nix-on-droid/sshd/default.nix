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

    if [ ! -f /tmp/sshd.pid ]; then
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

    environment.extraProfile = [
      ''
        ${startSshdScript}
      ''
    ];

    build.activation.setupSshdScript = ''
      #!/usr/bin/env bash
      $DRY_RUN_CMD mkdir -p /etc/ssh

      # Generate SSH host key if it doesn't exist
      if [ ! -f "/etc/ssh/ssh_host_rsa_key" ]; then
        $DRY_RUN_CMD ${pkgs.openssh}/bin/ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
      fi

      # Set up authorized_keys file
      AUTH_KEYS_FILE="/etc/ssh/authorized_keys"
      $DRY_RUN_CMD touch "$AUTH_KEYS_FILE"

      # Read existing keys into an array
      IFS=$'\n' read -d "" -r -a existing_keys < "$AUTH_KEYS_FILE"

      # Add new keys, avoiding duplicates
      echo "${cfg.authorizedKeys}" | while read -r new_key; do
        if [[ -n "$new_key" ]]; then
          is_duplicate=0
          for existing_key in "''${existing_keys[@]}"; do
            if [[ "$existing_key" == "$new_key" ]]; then
              is_duplicate=1
              break
            fi
          done
          if [[ $is_duplicate -eq 0 ]]; then
            $DRY_RUN_CMD echo "$new_key" >> "$AUTH_KEYS_FILE"
          fi
        fi
      done

      $DRY_RUN_CMD chmod 600 "$AUTH_KEYS_FILE"
    '';
  };
}
