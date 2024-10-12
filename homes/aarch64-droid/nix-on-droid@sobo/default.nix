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

  home.file.".config/syncthing/key.pem".source = config.age.secrets.sobo-syncthing-key.path;
  home.file.".config/syncthing/cert.pem".source = config.age.secrets.sobo-syncthing-cert.path;
}
