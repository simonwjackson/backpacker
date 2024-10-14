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
  home.packages = with pkgs; [
    asdf
  ];
}
