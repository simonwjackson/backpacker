{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault;
in {
  programs.bash.enable = true;

  mountainous = {
    # agenix.enable = mkDefault true;
    # atuin = {
    #   enable = true;
    #   key_path = config.age.secrets.atuin_key.path;
    #   session_path = config.age.secrets.atuin_session.path;
    # };
    # bat.enable = mkDefault true;
    eza.enable = mkDefault true;
    # git = {
    #   enable = mkDefault true;
    #   github-token = config.age.secrets."user-simonwjackson-github-token".path;
    # };
    # lf.enable = mkDefault true;
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

  home.packages = with pkgs; [
    rsync
  ];

  services = {
    # http-server = {
    #   enable = true;
    # };
    #
    # syncthingd = {
    #   enable = true;
    # };
    #
    # sshd = {
    #   enable = true;
    #   port = 2222;
    #   extraConfig = ''
    #     # Allow only nix-on-droid user
    #     AllowUsers nix-on-droid
    #
    #     Match Address !100.64.0.0/10,!172.16.0.0/12,!192.18.0.0/16
    #         PubkeyAuthentication no
    #   '';
    #   authorizedKeys = ''
    #     ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/PwyhdbVKd6jcG55m/1sUgEf0x3LUeS9H4EK5vk9PKhvDsjOQOISyR1LBmmXUFamkpFo2c84ZgPMj33qaPfOF0VfmF79vdAIDdDt5bmsTU6IbT7tGJ1ocpHDqhqbDO3693RdbTt1jTQN/eo3AKOfnrMouwBZPbPVqoWEhrLUvUTuTq7VQ+lUqWkvGs4D6D8UeIlG9VVgVhad3gCohYsjGdzgOUy0V4c8t3BuHrIE6//+6YVJ9VWK/ImSWmN8it5RIREDgdSYujs1Uod+ovr8AvaGFlFC9GuYMsj7xDYL1TgaWhy5ojk6JcuuF0cmoqffoW/apYdYM6Vxi5Xe6aJUhVyguZDovWcqRdPv2q0xtZn6xvNkoElEkrb6t0CAbGKf++H4h8/v5MsMt9wUPJAJBa24v0MlU8mXTUwhFLP5YQ/A8AAb5Y3ty/6DaOlvvTzt5Om2SMrZ1XaL1II35dFNZ/Os3zRpqdWq9SnpisRA+Bpf0bPUjdi8D8rRJn8g3zO5EsldBlZg82PiJcRHANbydTSK6Jzw7A8S5gMyPoH80Pq5MbQPvPpevTfOKy14NyTYPHGj0j5y7EQP7yb6w70LtqdRLRLQSTCdF0qTjVWw/qdt9MXkS7cdQe4yBADmjwozwPuxAs/jNpxELcVPEWBK6DcAIFD0vv3Xaw7reXpXFTQ==
    #   '';
    # };
  };
}
