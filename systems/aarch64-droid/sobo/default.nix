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
    diffutils
    findutils
    utillinux
    tzdata
    hostname
    gnugrep
    gnupg
    gnused
    gnutar
    bzip2
    gzip
    xz
    zip
    unzip
    openssh
    git
    hello
  ];

  # Backup etc files instead of failing to activate generation if a file already exists in /etc
  environment.etcBackupExtension = ".bak";

  # Read the changelog before changing this value
  system.stateVersion = "24.05";

  # Set up nix for flakes
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  services.syncthingd = {
    # keyFile = config.age.secrets.sobo-syncthing-cert.path;
    # certFile = config.age.secrets.sobo-syncthing-key.path;
  };

  # Set your time zone
  #time.timeZone = "Europe/Berlin";
}
