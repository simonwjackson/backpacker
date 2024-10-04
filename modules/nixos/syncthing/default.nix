{
  config,
  pkgs,
  lib,
  options,
  target,
  ...
}: let
  inherit (lib.backpacker) enabled;
  inherit (lib.backpacker.util) allArchitectures getAllHosts;
  inherit (lib.snowfall.fs) get-file;

  cfg = config.backpacker.syncthing;

  # Helper functions
  getSyncthingConfig = arch: host: let
    syncthingPath = "${cfg.systemsDir}/${arch}/${host}/syncthing.nix";
  in
    if builtins.pathExists syncthingPath
    then import syncthingPath {inherit config host;}
    else null;

  makeNamedConfig = arch: host: let
    config = getSyncthingConfig arch host;
  in
    if config != null
    then {
      name = host;
      value = config;
    }
    else null;

  getArchConfigs = arch: let
    hosts = getAllHosts cfg.systemsDir arch;
    configs = map (makeNamedConfig arch) hosts;
  in
    builtins.filter (item: item != null) configs;

  getAllArchConfigs = let
    archs = allArchitectures cfg.systemsDir;
    allConfigs = builtins.concatMap getArchConfigs archs;
  in
    allConfigs;

  # Helper function to check if a device has the specified share
  isDeviceInShare = shareName: config:
    config.shares ? "${shareName}";

  # Helper function to get devices for a specific share
  getDevicesForShare = shareName: hostName: config:
    if isDeviceInShare shareName config
    then [hostName]
    else [];

  getShareDevices = shareName: let
    devicesPerHost =
      lib.mapAttrsToList
      (hostName: config: getDevicesForShare shareName hostName config)
      allSyncthingConfigs;
  in
    lib.flatten devicesPerHost;

  # Helper function to check if a device has the specified share
  deviceHasShare = share: device:
    builtins.elem share device.shares;

  # Helper function to filter devices that have the specified share
  filterDevicesWithShare = devices: share:
    lib.filterAttrs (name: device: deviceHasShare share device) devices;

  # Main function to get names of devices with the specified share
  getDevicesWithShare = devices: share: let
    devicesWithShare = filterDevicesWithShare devices share;
  in
    builtins.attrNames devicesWithShare;

  getHostShares = lib.mapAttrsToList (name: value: {
    "${name}" =
      value
      // {
        devices = getShareDevices name ++ (getDevicesWithShare cfg.otherDevices name);
      };
  });

  # Configurations
  allSyncthingConfigs = builtins.listToAttrs getAllArchConfigs;

  deviceListFromOthers = lib.mapAttrs (name: value: {id = value.device.id;}) cfg.otherDevices;

  deviceListFromSystems = lib.mapAttrs (name: config: config.device) allSyncthingConfigs;

  sharesFromHost = host:
    lib.mkMerge (getHostShares
      (getSyncthingConfig target host).shares);

  generateWhitelistActivationScript = shares: let
    whitelistedShares = let
      contents = shares.contents or [];
      hasWhitelist = item:
        lib.hasAttrByPath [(builtins.head (builtins.attrNames item)) "whitelist"] item
        && (builtins.getAttr "whitelist" (builtins.getAttr (builtins.head (builtins.attrNames item)) item)) != false;

      whitelistedContents = lib.filter hasWhitelist contents;
    in
      whitelistedContents;

    getFirstKey = item: builtins.head (builtins.attrNames item);

    scriptForShare = item: let
      key = getFirstKey item;
      value = builtins.getAttr key item;
      whitelist = value.whitelist;

      generateWhitelistContent = whitelist:
        if builtins.isBool whitelist
        then "*"
        else let
          whitelistLines = map (line: "!${line}") whitelist;
          allLines = whitelistLines ++ ["*"];
        in
          builtins.concatStringsSep "\n" allLines;
    in ''
      STIGNORE_PATH="${value.path}/.stignore"

      # Create or update .stignore file
      ${
        if builtins.isBool whitelist
        then ''
          if [ -f "$STIGNORE_PATH" ]; then
            if ! ${pkgs.gnugrep}/bin/grep -q '^[*]$' "$STIGNORE_PATH"; then
              echo '*' >> "$STIGNORE_PATH"
              echo "Added '*' to $STIGNORE_PATH"
            fi
          else
            echo '*' > "$STIGNORE_PATH"
            echo "Created $STIGNORE_PATH with '*'"
          fi
        ''
        else ''
          # Handle list of whitelisted patterns
          cat > "$STIGNORE_PATH" << EOL
          ${generateWhitelistContent whitelist}
          EOL
          echo "Updated $STIGNORE_PATH with whitelist patterns"
        ''
      }
    '';

    # Generate scripts for all whitelisted shares
    scripts = map scriptForShare whitelistedShares;
  in
    builtins.concatStringsSep "\n" scripts;
in {
  # Options
  options.backpacker.syncthing =
    options.services.syncthing
    // {
      otherDevices = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            device = lib.mkOption {
              type = lib.types.submodule {
                options.id = lib.mkOption {
                  type = lib.types.str;
                  description = "Device ID";
                };
              };
              description = "Syncthing device configuration";
            };
            shares = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "List of share names to sync with the device";
            };
          };
        });
        default = {};
        description = "Configuration for other Syncthing devices";
      };

      systemsDir = lib.mkOption {
        type = lib.types.path;
        description = "Directory containing system configurations";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = config.backpacker.user.name;
        description = "User running Syncthing";
      };

      hostName = lib.mkOption {
        type = lib.types.str;
        default = config.networking.hostName;
        description = "Hostname for the current system";
      };
    };

  # Configuration
  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      overrideDevices = true;
      overrideFolders = true;
      key = cfg.key;
      cert = cfg.cert;
      user = cfg.user;
      configDir = "/home/${cfg.user}/.config/syncthing";

      settings = {
        ignores.line = [
          "**/node_modules"
          "**/build"
          "**/cache"
        ];

        folders = sharesFromHost cfg.hostName;
        devices = deviceListFromSystems // deviceListFromOthers;
      };

      extraFlags = [
        "--no-default-folder"
        # "--gui-address=0.0.0.0:8384"
      ];
    };

    # Activation script for whitelisted shares
    system.activationScripts.syncthingStignore = {
      supportsDryActivation = true;
      text = ''
        if [ "$NIXOS_ACTION" = "dry-activate" ]; then
          echo "Would ensure the .stignore files end with '*' for whitelisted Syncthing shares"
        else
          ${generateWhitelistActivationScript (sharesFromHost cfg.hostName)}
        fi
      '';
    };
  };
}
