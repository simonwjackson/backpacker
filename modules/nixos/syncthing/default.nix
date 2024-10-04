# Imports and inheritances
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

  # Helper function to check if a device has the specified folder
  isDeviceInFolder = folderName: config:
    config.paths ? "${folderName}";

  # Helper function to get devices for a specific folder
  getDevicesForFolder = folderName: hostName: config:
    if isDeviceInFolder folderName config
    then [hostName]
    else [];

  getFolderDevices = folderName: let
    devicesPerHost =
      lib.mapAttrsToList
      (hostName: config: getDevicesForFolder folderName hostName config)
      allSyncthingConfigs;
  in
    lib.flatten devicesPerHost;

  # Helper function to check if a device has the specified folder
  deviceHasFolder = folder: device:
    builtins.elem folder device.folders;

  # Helper function to filter devices that have the specified folder
  filterDevicesWithFolder = devices: folder:
    lib.filterAttrs (name: device: deviceHasFolder folder device) devices;

  # Main function to get names of devices with the specified folder
  getDevicesWithFolder = devices: folder: let
    devicesWithFolder = filterDevicesWithFolder devices folder;
  in
    builtins.attrNames devicesWithFolder;

  getHostFolders = lib.mapAttrsToList (name: value: {
    "${name}" = {
      path = value;
      devices = getFolderDevices name ++ (getDevicesWithFolder cfg.otherDevices name);
    };
  });

  # Configurations
  allSyncthingConfigs = builtins.listToAttrs getAllArchConfigs;

  deviceListFromOthers = lib.mapAttrs (name: value: {id = value.device.id;}) cfg.otherDevices;

  deviceListFromSystems = lib.mapAttrs (name: config: config.device) allSyncthingConfigs;

  foldersFromHost = host:
    lib.mkMerge (getHostFolders
      (getSyncthingConfig target host).paths);
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
            folders = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "List of folder names to sync with the device";
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

        folders = foldersFromHost cfg.hostName;

        devices = deviceListFromSystems // deviceListFromOthers;
      };

      extraFlags = [
        "--no-default-folder"
        # "--gui-address=0.0.0.0:8384"
      ];
    };
  };
}
