{
  config,
  lib,
  pkgs,
  ...
}: {
  # Simply install just the packages
  environment.packages = with pkgs; [
    vim
    procps
    killall
    findutils
    utillinux
    tzdata
    hostname
    man
    gnugrep
    gnused
    openssh
    git
  ];

  # Backup etc files instead of failing to activate generation if a file already exists in /etc
  environment.etcBackupExtension = ".bak";

  # Set up nix for flakes
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Set your time zone
  #time.timeZone = "Europe/Berlin";
}
