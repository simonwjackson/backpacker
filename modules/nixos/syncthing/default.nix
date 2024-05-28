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

  deviceListFromOthers = lib.mapAttrs (name: value: {id = value.device.id;}) cfg.otherDevices;

  getSyncthingConfig = arch: host: let
    syncthingPath = "${cfg.systemsDir}/${arch}/${host}/syncthing.nix";
  in
    if builtins.pathExists syncthingPath
    then import syncthingPath {inherit config host;}
    else null;

  allSyncthingConfigs = builtins.listToAttrs (builtins.concatMap (
      arch:
        builtins.filter (item: item != null) (map (
          host: let
            config = getSyncthingConfig arch host;
          in
            if config != null
            then {
              name = host;
              value = config;
            }
            else null
        ) (getAllHosts cfg.systemsDir arch))
    )
    (allArchitectures cfg.systemsDir));

  getFolderDevices = name:
    lib.flatten (lib.mapAttrsToList
      (hostName: config: lib.optionals (config.paths ? "${name}") [hostName])
      allSyncthingConfigs);

  getDevicesWithFolder = devices: folder: let
    hasFolder = device: builtins.elem folder device.folders;
  in
    builtins.attrNames (lib.filterAttrs (name: device: hasFolder device) devices);

  getHostFolders =
    lib.mapAttrsToList
    (name: value: {
      "${name}" = {
        path = value;
        devices = getFolderDevices name ++ (getDevicesWithFolder cfg.otherDevices name);
      };
    });

  deviceListFromSystems = lib.mapAttrs (name: config: config.device) allSyncthingConfigs;

  foldersFromHost = host:
    lib.mkMerge (getHostFolders
      (getSyncthingConfig target host).paths);
in {
  options.backpacker.syncthing =
    {
      enable = lib.mkEnableOption "Whether to enable syncthing";

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
        description = "";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = config.backpacker.user.name;
        description = "";
      };

      hostName = lib.mkOption {
        type = lib.types.str;
        default = config.networking.hostName;
        description = "";
      };
    }
    // options.services.syncthing;

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      overrideDevices = true;
      overrideFolders = true;
      key = cfg.key;
      cert = cfg.cert;
      user = cfg.user;
      # BUG: Pass in full dir
      configDir = "/home/${cfg.user}/.config/syncthing";

      settings = {
        ignores.line = [
          "**/node_modules"
          "**/build"
          "**/cache"
        ];

        folders = foldersFromHost cfg.hostName;

        devices =
          deviceListFromSystems
          // deviceListFromOthers;
      };

      extraFlags = [
        "--no-default-folder"
        # "--gui-address=0.0.0.0:8384"
      ];
    };
  };
}
