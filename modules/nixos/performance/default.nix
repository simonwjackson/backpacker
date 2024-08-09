{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.backpacker) enabled;

  cfg = config.backpacker.performance;
  powertop = lib.getExe pkgs.powertop;
in {
  options.backpacker.performance = {
    enable = lib.mkEnableOption "Enable performance tuning";
  };

  config = lib.mkIf cfg.enable {
    services = {
      # auto-cpufreq = enabled;
      thermald.enable = config.backpacker.hardware.cpu.type == "intel";
      # a shell daemon created to manage processes' IO and CPU priorities, with community-driven set of rule
      ananicy = {
        enable = true;
        package = pkgs.ananicy-cpp;
      };
    };

    powerManagement = {
      enable = true;
      powertop.enable = true;
      cpuFreqGovernor = pkgs.lib.mkDefault "powersave";
    };

    programs.ccache = enabled;

    systemd.services.powertop = lib.mkIf config.backpacker.hardware.battery.enable {
      # description = "Auto-tune Power Management with powertop";
      unitConfig = {RefuseManualStart = true;};
      wantedBy = ["battery.target" "ac.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${powertop} --auto-tune";
      };
    };

    zramSwap = enabled;
  };
}
