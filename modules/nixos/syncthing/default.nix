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

  # Extracted common functions
  importConfigIfExists = configPath: host:
    if builtins.pathExists configPath
    then import configPath {inherit config host;}
    else null;

  createNamedConfig = importConfigFn: architecture: hostname: let
    importedConfig = importConfigFn architecture hostname;
  in
    if importedConfig != null
    then {
      name = hostname;
      value = importedConfig;
    }
    else null;

  getConfigsForArchitecture = importConfigFn: architecture: let
    hostsForArch = getAllHosts cfg.systemsDir architecture;
    archConfigs = map (createNamedConfig importConfigFn architecture) hostsForArch;
  in
    builtins.filter (item: item != null) archConfigs;

  getAllArchitectureConfigs = importConfigFn: let
    architectures = allArchitectures cfg.systemsDir;
    allArchConfigs = builtins.concatMap (getConfigsForArchitecture importConfigFn) architectures;
  in
    allArchConfigs;

  importSyncthingConfig = architecture: hostname:
    importConfigIfExists "${cfg.systemsDir}/${architecture}/${hostname}/syncthing.nix" hostname;

  allSyncthingConfigs = builtins.listToAttrs (getAllArchitectureConfigs importSyncthingConfig);

  # Helper function for checking if a device has a specific share
  deviceHasShare = shareName: deviceConfig: deviceConfig.shares ? "${shareName}";

  # Helper function to get devices for a specific share
  getDevicesWithShare = shareName:
    lib.mapAttrsToList
    (deviceName: deviceConfig:
      if deviceHasShare shareName deviceConfig
      then [deviceName]
      else []);

  getDevicesForShare = shareName:
    lib.flatten (getDevicesWithShare shareName allSyncthingConfigs);

  # Helper function to filter devices that have the specified share
  filterDevicesByShare = shareName:
    lib.filterAttrs
    (deviceName: deviceConfig: builtins.elem shareName deviceConfig.shares);

  # Main function to get names of devices with the specified share
  getDeviceNamesForShare = shareName: devices:
    builtins.attrNames (filterDevicesByShare shareName devices);

  createShareConfig = lib.mapAttrsToList (shareName: shareConfig: {
    "${shareName}" =
      shareConfig
      // {
        devices = getDevicesForShare shareName ++ (getDeviceNamesForShare shareName cfg.otherDevices);
      };
  });

  getArchConfigs = arch: let
    hosts = getAllHosts cfg.systemsDir arch;
    configs = map (createNamedConfig arch) hosts;
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

  deviceListFromOthers = lib.mapAttrs (name: value: {id = value.device.id;}) cfg.otherDevices;

  deviceListFromSystems = lib.mapAttrs (name: config: config.device) allSyncthingConfigs;

  sharesFromHost = host:
    lib.mkMerge (createShareConfig
      (importSyncthingConfig target host).shares);

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

  generateBlacklistActivationScript = shares: let
    blacklistedShares = let
      contents = shares.contents or [];
      hasBlacklist = item:
        lib.hasAttrByPath [(builtins.head (builtins.attrNames item)) "blacklist"] item
        && (builtins.getAttr "blacklist" (builtins.getAttr (builtins.head (builtins.attrNames item)) item)) != false;

      blacklistedContents = lib.filter hasBlacklist contents;
    in
      blacklistedContents;

    getFirstKey = item: builtins.head (builtins.attrNames item);

    scriptForShare = item: let
      key = getFirstKey item;
      value = builtins.getAttr key item;
      blacklist = value.blacklist;

      generateBlacklistContent = blacklist:
        if builtins.isList blacklist
        then builtins.concatStringsSep "\\n" (map lib.escapeShellArg blacklist)
        else "";
    in ''
      STIGNORE_PATH="${value.path}/.stignore"

      # Create or update .stignore file with blacklist
      ${
        if builtins.isList blacklist
        then ''
          if [ -f "$STIGNORE_PATH" ]; then
            # Ensure each blacklisted pattern is in the file
            ${builtins.concatStringsSep "\n" (map (pattern: ''
              if ! ${pkgs.gnugrep}/bin/grep -qFx ${lib.escapeShellArg pattern} "$STIGNORE_PATH"; then
                echo ${lib.escapeShellArg pattern} >> "$STIGNORE_PATH"
                echo "Added '${pattern}' to $STIGNORE_PATH"
              fi
            '')
            blacklist)}
          else
            echo -e "${generateBlacklistContent blacklist}" > "$STIGNORE_PATH"
            echo "Created $STIGNORE_PATH with blacklist patterns"
          fi
        ''
        else ''
          # Do nothing if blacklist is not a list
          echo "Blacklist is not defined or is set to false for ${key}"
        ''
      }
    '';

    # Generate scripts for all blacklisted shares
    scripts = map scriptForShare blacklistedShares;
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

    # Activation script for whitelisted and blacklisted shares
    system.activationScripts.syncthingStignore = {
      supportsDryActivation = true;
      text = let
        shares = sharesFromHost cfg.hostName;
        whitelistScript = generateWhitelistActivationScript shares;
        blacklistScript = generateBlacklistActivationScript shares;
      in ''
        if [ "$NIXOS_ACTION" = "dry-activate" ]; then
          echo "Would ensure the .stignore files are updated for whitelisted and blacklisted Syncthing shares"
        else
          ${whitelistScript}
          ${blacklistScript}
        fi
      '';
    };

    # Assert that whitelist and blacklist are not used simultaneously
    assertions = [
      {
        assertion = let
          shares = sharesFromHost cfg.hostName;
          hasWhitelistAndBlacklist = item:
            lib.hasAttrByPath [(builtins.head (builtins.attrNames item)) "whitelist"] item
            && lib.hasAttrByPath [(builtins.head (builtins.attrNames item)) "blacklist"] item;
          conflictingShares = builtins.filter hasWhitelistAndBlacklist (shares.contents or []);
        in
          builtins.length conflictingShares == 0;
        message = "Cannot use both whitelist and blacklist for the same Syncthing share";
      }
    ];
  };
}
