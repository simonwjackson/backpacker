{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf optionalString types concatStringsSep;

  cfg = config.backpacker.programs.mosh;

  moshWrapped = pkgs.symlinkJoin {
    name = "mosh-wrapped";
    paths = [cfg.package];
    buildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/mosh \
        ${optionalString (cfg.client != null) "--add-flags \"--client=${cfg.client}\""} \
        ${optionalString (cfg.server != null) "--add-flags \"--server=${cfg.server}\""} \
        ${optionalString (cfg.predict != null) "--add-flags \"--predict=${cfg.predict}\""} \
        ${optionalString cfg.predictOverwrite "--add-flags \"--predict-overwrite\""} \
        ${optionalString (cfg.family != null) "--add-flags \"--family=${cfg.family}\""} \
        ${optionalString (cfg.port != null) "--add-flags \"--port=${cfg.port}\""} \
        ${optionalString (cfg.bindServer != null) "--add-flags \"--bind-server=${cfg.bindServer}\""} \
        ${optionalString (cfg.ssh != null) "--add-flags \"--ssh=${cfg.ssh}\""} \
        ${optionalString cfg.noSshPty "--add-flags \"--no-ssh-pty\""} \
        ${optionalString cfg.noInit "--add-flags \"--no-init\""} \
        ${optionalString cfg.local "--add-flags \"--local\""} \
        ${optionalString (cfg.experimentalRemoteIp != null) "--add-flags \"--experimental-remote-ip=${cfg.experimentalRemoteIp}\""} \
        ${optionalString (cfg.extraOptions != []) "--add-flags \"${concatStringsSep " " cfg.extraOptions}\""}
    '';
  };
in {
  options.backpacker.programs.mosh = {
    enable = mkEnableOption "mosh";

    package = mkOption {
      type = types.package;
      default = pkgs.mosh;
      description = "The mosh package to use.";
    };

    extraOptions = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["--predict=always"];
      description = "Additional command-line arguments to pass to mosh.";
    };

    client = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to mosh client on local machine.";
    };

    server = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Command for mosh server on remote machine.";
    };

    predict = mkOption {
      type = types.nullOr (types.enum ["adaptive" "always" "never" "experimental"]);
      default = null;
      description = "Prediction mode for local echo.";
    };

    predictOverwrite = mkOption {
      type = types.bool;
      default = false;
      description = "Whether prediction overwrites instead of inserting.";
    };

    family = mkOption {
      type = types.nullOr (types.enum ["inet" "inet6" "auto" "all" "prefer-inet" "prefer-inet6"]);
      default = null;
      description = "Network family to use.";
    };

    port = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "60000:61000";
      description = "Server-side UDP port or range.";
    };

    bindServer = mkOption {
      type = types.nullOr (types.enum ["ssh" "any"]);
      default = null;
      description = "Ask the server to reply from a specific IP address.";
    };

    ssh = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "ssh -p 2222";
      description = "SSH command to run when setting up session.";
    };

    noSshPty = mkOption {
      type = types.bool;
      default = false;
      description = "Do not allocate a pseudo tty on ssh connection.";
    };

    noInit = mkOption {
      type = types.bool;
      default = false;
      description = "Do not send terminal initialization string.";
    };

    local = mkOption {
      type = types.bool;
      default = false;
      description = "Run mosh-server locally without using ssh.";
    };

    experimentalRemoteIp = mkOption {
      type = types.nullOr (types.enum ["local" "remote" "proxy"]);
      default = null;
      description = "Method for discovering the remote IP address to use for mosh.";
    };
  };

  config = mkIf cfg.enable {
    environment.packages = [
      moshWrapped
    ];

    build.activation.symlinkMosh = ''
      #!/usr/bin/env bash

      $VERBOSE_ECHO "Symlinking mosh to /usr/bin/"

      for app in ${moshWrapped}/bin/*; do
        appname=$(${pkgs.coreutils}/bin/basename "$app")
        $VERBOSE_ECHO "Symlinking $appname"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sf $VERBOSE_ARG "$app" "/usr/bin/$appname"
      done
    '';
  };
}
