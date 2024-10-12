{
  config,
  lib,
  pkgs,
  ...
}: {
  android-integration.am.enable = true;
  android-integration.termux-open.enable = true;
  android-integration.termux-open-url.enable = true;
  android-integration.termux-reload-settings.enable = true;
  android-integration.termux-wake-lock.enable = true;
  android-integration.termux-wake-unlock.enable = true;
  android-integration.xdg-open.enable = true;

  terminal.font = "${pkgs.nerdfonts.override {fonts = ["Terminus"];}}/share/fonts/truetype/NerdFonts/TerminessNerdFontMono-Regular.ttf";

  backpacker = {
    programs.mosh = {
      enable = true;
      experimentalRemoteIp = "remote";
    };
  };

  environment = {
    # Backup etc files instead of failing to activate generation if a file already exists in /etc
    etcBackupExtension = ".bak";
    packages = with pkgs; [
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
      coreutils
      git
      glibcLocales
      ncurses # clear cmd
    ];

    sessionVariables = {
      # Fix locale (perl apps panic without it)
      LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  # Set up nix for flakes
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  services.syncthingd = {
    enable = true;
    keyFile = "${config.user.home}/.config/syncthing/key.pem";
    certFile = "${config.user.home}/.config/syncthing/cert.pem";
  };

  # Set your time zone
  #time.timeZone = "Europe/Berlin";
}
