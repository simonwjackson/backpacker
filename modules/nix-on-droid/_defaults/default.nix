{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  options = {
    environment.extraProfile = lib.mkOption {
      type = lib.types.listOf lib.types.lines;
      default = [];
      description = ''
        Additional shell commands to be appended to /etc/profile.
        This option can be used multiple times across different modules.
        The contents will be added to the end of the profile file.
      '';
    };
  };

  config = {
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
        cowsay
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

    environment.etc."profile".text = lib.mkAfter ''
      ${lib.concatStringsSep "\n" config.environment.extraProfile}
    '';

    services = {
      syncthingd = {
        enable = true;
      };

      sshd = {
        enable = true;
        port = 2222;
        extraConfig = ''
          # Allow only nix-on-droid user
          AllowUsers nix-on-droid

          Match Address !100.64.0.0/10,!172.16.0.0/12,!192.18.0.0/16
              PubkeyAuthentication no
        '';
        authorizedKeys = let
          keysDir = "${inputs.secrets}/keys/users";
          isPublicKey = name: type: type == "regular" && lib.hasSuffix ".pub" name;
          pubKeyFiles = lib.filterAttrs isPublicKey (builtins.readDir keysDir);
          keys = lib.mapAttrsToList (name: _: builtins.readFile (keysDir + "/${name}")) pubKeyFiles;
        in
          builtins.concatStringsSep "\n" keys;
      };
    };

    # Set your time zone
    #time.timeZone = "Europe/Berlin";
  };
}
