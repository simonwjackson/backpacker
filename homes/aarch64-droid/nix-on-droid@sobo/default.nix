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
    keyFile = config.age.secrets.sobo-syncthing-cert.path;
    certFile = config.age.secrets.sobo-syncthing-key.path;
  };
}
