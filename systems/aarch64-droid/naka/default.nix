{
  config,
  lib,
  pkgs,
  ...
}: {
  # Read the changelog before changing this value
  system.stateVersion = "24.05";

  # TODO: add agenix
  services.syncthingd = {
    certFile = "${config.user.home}/.local/run/agenix/naka-syncthing-cert";
    keyFile = "${config.user.home}/.local/run/agenix/naka-syncthing-key";
  };
}
