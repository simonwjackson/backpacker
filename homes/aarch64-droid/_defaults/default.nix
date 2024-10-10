{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault;
in {
  mountainous = {
    # agenix.enable = mkDefault true;
    # atuin = {
    #   enable = true;
    #   key_path = config.age.secrets.atuin_key.path;
    #   session_path = config.age.secrets.atuin_session.path;
    # };
    bat.enable = mkDefault true;
    eza.enable = mkDefault true;
    # git = {
    #   enable = mkDefault true;
    #   github-token = config.age.secrets."user-simonwjackson-github-token".path;
    # };
    lf.enable = mkDefault true;
    # xpo.enable = mkDefault true;
    # zsh.enable = mkDefault true;
  };
  home.file.".bashrc".text = let
    dnshack = pkgs.callPackage (builtins.fetchTarball "https://github.com/ettom/dnshack/tarball/master") {};
  in ''
    export DNSHACK_RESOLVER_CMD="${dnshack}/bin/dnshackresolver"
    export LD_PRELOAD="${dnshack}/lib/libdnshackbridge.so"
  '';
  # home.file.".bashrc".text = ''
  #   export DNSHACK_RESOLVER_CMD="${dnshack}/bin/dnshackresolver"
  #   export LD_PRELOAD="${dnshack}/lib/libdnshackbridge.so"
  # '';
}
