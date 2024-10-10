{
  config,
  lib,
  pkgs,
  ...
}: {
  mountainous.eza.enable = true;

  # Read the changelog before changing this value
  home.stateVersion = "24.05";
}
