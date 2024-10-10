{
  config,
  lib,
  pkgs,
  ...
}: {
  # Read the changelog before changing this value
  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    rsync
    openssh
    git
    fd
    ripgrep
    jq
    yq-go
    cowsay
  ];

  home.file.".bashrc".text = let
    dnshack = pkgs.callPackage (builtins.fetchTarball "https://github.com/ettom/dnshack/tarball/master") {};
  in ''
    export DNSHACK_RESOLVER_CMD="${dnshack}/bin/dnshackresolver"
    export LD_PRELOAD="${dnshack}/lib/libdnshackbridge.so"
  '';
}
