{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) mkDefault mkEnableOption mkOption types mkIf hm mkForce value;
in {
  programs.bash.enable = true;

  home.file."storage".source = config.lib.file.mkOutOfStoreSymlink "/storage/emulated/0";
  home.file."snowscape".source = config.lib.file.mkOutOfStoreSymlink "/storage/emulated/0/snowscape";

  home.activation.setupAgenix = let
    secretsToJson =
      lib.mapAttrs (
        name: value:
          lib.filterAttrs (n: v: n != "_module") value
      )
      config.age.secrets;

    secretsJson = builtins.toJSON secretsToJson;

    jq = "${pkgs.jq}/bin/jq";
    agenix = "${inputs.mountainous.inputs.agenix.packages.aarch64-linux.default}/bin/agenix";
  in
    # TODO: create keys in agenix.d then symlink them to agenix
    hm.dag.entryBefore ["checkLinkTargets"]
    ''
      #!/usr/bin/env bash
      $DRY_RUN_CMD mkdir -p \
        "${config.home.sessionVariables.XDG_RUNTIME_DIR}/agenix" \
        "${config.home.sessionVariables.XDG_RUNTIME_DIR}/agenix.d"

      # Change to the secrets directory
      cd ${inputs.secrets}/agenix

      echo '${secretsJson}' > ${config.home.homeDirectory}/asdf.txt

      # Decrypt secrets
      echo '${secretsJson}' | ${jq} -r 'to_entries[] | "${agenix} --identity ${config.home.homeDirectory}/.ssh/id_rsa --decrypt \(.value.file | split("/") | last) > \(.value.path)"' | while read -r cmd; do
        $DRY_RUN_CMD eval "$cmd"
      done
    '';

  age = {
    secretsDir = "${config.home.sessionVariables.XDG_RUNTIME_DIR}/agenix";
    secretsMountPoint = "${config.home.sessionVariables.XDG_RUNTIME_DIR}/agenix.d";
    identityPaths = mkForce [
      "${config.home.homeDirectory}/.ssh/id_rsa"
      "${config.home.homeDirectory}/.ssh/ssh_host_rsa_key"
    ];
  };

  home.sessionVariables = {
    XDG_CACHE_HOME = "${config.home.homeDirectory}/.cache";
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
    XDG_DATA_HOME = "${config.home.homeDirectory}/.local/share";
    XDG_STATE_HOME = "${config.home.homeDirectory}/.local/state";
    XDG_RUNTIME_DIR = "${config.home.homeDirectory}/.local/run";
  };

  # Create all XDG directories early in the activation process
  home.activation = {
    createXdgDirs = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
      $DRY_RUN_CMD mkdir -p \
        ${config.home.sessionVariables.XDG_CACHE_HOME} \
        ${config.home.sessionVariables.XDG_CONFIG_HOME} \
        ${config.home.sessionVariables.XDG_DATA_HOME} \
        ${config.home.sessionVariables.XDG_STATE_HOME} \
        ${config.home.sessionVariables.XDG_RUNTIME_DIR}

      $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod 700 \
        ${config.home.sessionVariables.XDG_CACHE_HOME} \
        ${config.home.sessionVariables.XDG_CONFIG_HOME} \
        ${config.home.sessionVariables.XDG_DATA_HOME} \
        ${config.home.sessionVariables.XDG_STATE_HOME} \
        ${config.home.sessionVariables.XDG_RUNTIME_DIR} \
        ${config.home.homeDirectory}/.local
    '';
  };

  # home.file."somepass" = {
  #   executable = false;
  #   text =
  #     # bash
  #     ''
  #       ${builtins.readFile config.age.secrets.atuin_session.path};
  #     '';
  # };

  mountainous = {
    agenix = {
      enable = true;
      secretMode = "0770";
      secretSymlinks = false;
      secretsDir = "${inputs.secrets}/agenix";
    };
    atuin = {
      enable = true;
      key_path = mkForce config.age.secrets.atuin_key.path;
      session_path = mkForce config.age.secrets.atuin_session.path;
    };
    # bat.enable = mkDefault true;
    eza.enable = mkDefault true;
    git = {
      enable = mkDefault true;
      github-token = config.age.secrets."user-simonwjackson-github-token".path;
    };
    lf.enable = mkDefault true;
    # xpo.enable = mkDefault true;
    # zsh.enable = mkDefault true;
  };

  programs.bash.initExtra = let
    dnshack = pkgs.callPackage inputs.dnshack {};
  in ''
    export DNSHACK_RESOLVER_CMD="${dnshack}/bin/dnshackresolver"
    export LD_PRELOAD="${dnshack}/lib/libdnshackbridge.so"
  '';
  # ${builtins.readFile config.age.secrets."user-simonwjackson-github-token".path}

  home.packages = with pkgs; [
    inputs.mountainous.inputs.agenix.packages.${system}.default
    rsync
    openssh
    git
    fd
    ripgrep
    jq
    yq-go
    asdf
  ];

  services = {
    # http-server = {
    #   enable = true;
    # };

    syncthingd = {
      enable = true;
    };

    sshd = {
      enable = true;
      port = 2222;
      extraConfig = ''
        # Allow only nix-on-droid user
        AllowUsers nix-on-droid

        Match Address !100.64.0.0/10,!172.16.0.0/12,!192.18.0.0/16
            PubkeyAuthentication no
      '';
      authorizedKeys = let
        keysDir = "${inputs.secrets}/keys/users";
        isPublicKey = name: type: type == "regular" && lib.hasSuffix ".pub" name;
        pubKeyFiles = lib.filterAttrs isPublicKey (builtins.readDir keysDir);
        keys = lib.mapAttrsToList (name: _: builtins.readFile (keysDir + "/${name}")) pubKeyFiles;
      in
        builtins.concatStringsSep "\n" keys;
    };
  };
}
