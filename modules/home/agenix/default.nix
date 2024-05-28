{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkOption;
  inherit (builtins) filter pathExists;
  inherit (lib.attrsets) mapAttrs' nameValuePair;
  inherit (lib.modules) mkDefault;
  inherit (lib.strings) removeSuffix;

  secretsFile = "${cfg.secretsDir}/secrets.nix";

  cfg = config.backpacker.agenix;
in {
  options.backpacker.agenix = {
    enable = mkEnableOption "Whether to enable agenix";

    secretsDir = mkOption {
      type = lib.types.path;
      description = "";
    };
  };

  config = lib.mkIf cfg.enable {
    # environment.systemPackages = [ragenix.packages.x86_64-linux.default];
    age = {
      identityPaths =
        options.age.identityPaths.default
        ++ [
          "${config.home.homeDirectory}/.ssh/agenix"
        ];

      secrets =
        if pathExists secretsFile
        then
          mapAttrs' (n: _:
            nameValuePair (removeSuffix ".age" n) {
              file = "${cfg.secretsDir}/${n}";
            }) (import secretsFile)
        else {};
    };

    # age.identityPaths = options.age.identityPaths.default ++ (filter pathExists [
    #   "${config.user.home}/.ssh/id_ed25519"
    #   "${config.user.home}/.ssh/id_rsa"
    # ]);
  };
}
