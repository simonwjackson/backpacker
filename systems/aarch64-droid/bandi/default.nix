{
  config,
  lib,
  pkgs,
  ...
}: {
  # Simply install just the packages
  environment.packages = with pkgs; [
    vim
    openssh
    git
  ];

  # Backup etc files instead of failing to activate generation if a file already exists in /etc
  environment.etcBackupExtension = ".bak";

  # Read the changelog before changing this value
  system.stateVersion = "24.05";

  # Set up nix for flakes
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # TODO: add agenix
  services.syncthingd = {
    certFile = "${config.user.home}/.local/run/agenix/bandi-syncthing-cert";
    keyFile = "${config.user.home}/.local/run/agenix/bandi-syncthing-key";
  };

  # Set your time zone
  #time.timeZone = "Europe/Berlin";
}
