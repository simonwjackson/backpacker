{ config, lib, ... }:

{
  services.syncthing = {
    overrideDevices = true;
    overrideFolders = true;
    # TODO: change this to mainUser
    user = "simonwjackson";
    configDir = "/home/simonwjackson/.config/syncthing";

    settings = {
      ignores = {
        "line" = [
          "**/node_modules"
          "**/build"
          "**/cache"
        ];
      };

      folderSettings = {
        notes = {
          devices = [ "fiji" "unzen" "yabashi" ];
        };

        documents = {
          devices = [ "fiji" "unzen" "yabashi" ];
        };

        code = {
          devices = [ "fiji" ];
          # devices = [ "fiji" "unzen" "yari" ];
        };

        taskwarrior = {
          devices = [ "fiji" ];
          # devices = ["fiji" "unzen" "zao" ];
        };
      };

      # Only setup shares that have been enabled in the host's config file
      folders = lib.mkMerge (
        lib.mapAttrsToList
          (name: value: {
            "${name}" = {
              path = value;
              devices = config.services.syncthing.settings.folderSettings."${name}".devices;
            };
          })
          config.services.syncthing.settings.paths
      );

      devices = {
        fiji = {
          id = "ABVHUQR-BIPNGCS-W7RGGEV-HBA3R4C-UWQAYWQ-KCBPJ6D-PIPLQYU-CXHOWAD";
          name = "laptop (fiji)";
        };

        unzen = {
          id = "ETEYYE4-C3P2L34-HIV54WA-XQRERGB-LXL5ZRZ-FVA4EXR-YUDRQVL-HV2FDQA";
          name = "home server (unzen)";
        };

        yabashi = {
          id = "MX3MDCS-DBIX5DN-4KCI7IF-DY652C3-FYO3V33-HWPPUQU-HL4USN5-4JOQKQD";
          name = "remote server (yabashi)";
        };

        #   zao = {
        #     id = "";
        #     name = "gaming (zao)";
        #   };

        #   usu = {
        #     id = "";
        #     name = "main phone (usu)";
        #   };

        #   yari = {
        #     id = "";
        #     name = "tablet (yari)";
        #   };
      };
    };

    extraFlags = [
      "--no-default-folder"
      "--gui-address=0.0.0.0:8384"
    ];
  };
}
# gaming-games.path = "/glacier/snowscape/gaming/games";
# gaming-launchers.path = "/glacier/snowscape/gaming/launchers";
# gaming-profiles.path = "/glacier/snowscape/gaming/profiles";
# gaming-systems.path = "/glacier/snowscape/gaming/systems";

# gaming-games.devices = [ "fiji" "unzen" "yari" "zao" ];
# gaming-launchers.devices = [ "fiji" "unzen" "zao" ];
# gaming-profiles.devices = [ "fiji" "usu" "unzen" "yari" "zao" ];
# gaming-systems.devices = [ "fiji" "unzen" "zao" ];

# gaming-profiles.versioning = {
#   type = "staggered";
#   params = {
#     cleanInterval = "3600";
#     maxAge = "31536000";
#   };
# };
