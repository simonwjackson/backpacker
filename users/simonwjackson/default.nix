{ config, pkgs, ... }:

{
  imports = [
    ./desktop
    ./terminal
    ../../modules/neovim

    # Scripts
    ./bin/wikis
    ./bin/scale-desktop
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = "simonwjackson";
    homeDirectory = "/home/simonwjackson";
  };

  home.packages = [
    pkgs.git-crypt
    pkgs.p7zip
    pkgs.killall
  ];

  programs.gpg = {
    enable = true;
  };

  services.gpg-agent = {
    enable = true;
    pinentryFlavor = "gnome3";
  };

  services.udiskie = {
    enable = true;
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}