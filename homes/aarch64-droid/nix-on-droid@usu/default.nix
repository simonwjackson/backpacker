{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault;
in {
  # Read the changelog before changing this value
  home.stateVersion = "24.05";

  services.syncthingd = {
    # keyFile = config.age.secrets.usu-syncthing-cert.path;
    # certFile = config.age.secrets.usu-syncthing-key.path;
  };
}
