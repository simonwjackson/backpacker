{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}: let
  inherit (lib) mkIf mkEnableOption mkOpt;

  tmesh = lib.getExe inputs.tmesh.packages.${system}.default;
  cfg = config.backpacker.desktops.hyprland;
in {
  imports = [
    inputs.hyprland.homeManagerModules.default
  ];
  # ++ lib.snowfall.fs.get-non-default-nix-files ./.;

  options.backpacker.desktops.hyprland = {
    enable = mkEnableOption "enable hyprland window manager";

    autoLogin = lib.mkEnableOption "Whether to auto login to the plasma desktop";
  };

  # FIX: this hack to use nix catppuccin module: https://github.com/catppuccin/nix/issues/102
  # options.wayland.windowManager.hyprland = {
  #   settings = mkEnableOption "enable hyprland window manager";
  # };

  config = mkIf cfg.enable {
    nix.settings = {
      trusted-substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };

    wayland.windowManager.hyprland.systemd.variables = ["-all"];

    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        "$mod" = "SUPER";
        windowrule = [
          "tile,^(kitty)$"
        ];
        animation = [
          "workspaces,1,8,default"
          "windows,0"
          "fade,0"
        ];
        monitor = [
          "DP-1,2560x1440@360,0x0,1"
          "DP-1,addreserved,50,50,400,400"
          "DP-2,2560x1440@360,0x0,1"
          "DP-2,addreserved,50,50,400,400"
          "DP-3,2560x1440@360,0x0,1"
          "DP-3,addreserved,50,50,400,400"
          "DP-4,2560x1440@360,0x0,1"
          "DP-4,addreserved,50,50,400,400"
        ];
        bindm = [
          "$mod, mouse:272, moveactive"
          "$mod, mouse:273, resizewindow"
        ];
        bind =
          [
            # Focus windows
            "$mod, h, movefocus, l"
            "$mod, j, movefocus, d"
            "$mod, k, movefocus, u"
            "$mod, l, movefocus, r"

            # Apps
            "$mod, w, exec, firefox-esr"
            # "$mod, p, exec, ${pkgs.procps}/bin/pgrep -f 'main-term' > /dev/null || ${lib.getExe pkgs.kitty} --class main-term ${tmesh}"
            "$mod, t, exec, ${lib.getExe pkgs.kitty}"

            # Toggle monocle mode for the focused window
            "$mod, m, fullscreen, 1"

            # Toggle pseudo-fullscreen mode for the focused window
            "$mod_SHIFT, f, fullscreen, 0"

            # Cycle through windows
            "$mod, Tab, cyclenext"
            "$mod_SHIFT, Tab, cyclenext, prev"

            # Cycle through windows in all workspaces
            "$mod_ALT_CTRL, Tab, cyclenext, allworkspaces"
            "$mod_ALT_CTRL_SHIFT, Tab, cyclenext, prev, allworkspaces"
          ]
          ++ (
            # workspaces
            # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
            builtins.concatLists (builtins.genList (
                x: let
                  ws = let
                    c = (x + 1) / 10;
                  in
                    builtins.toString (x + 1 - (c * 10));
                in [
                  "$mod, ${ws}, workspace, ${toString (x + 1)}"
                  "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
                ]
              )
              10)
          );
      };
    };

    # xdg.configFile."hypr".recursive = true;
  };
}
