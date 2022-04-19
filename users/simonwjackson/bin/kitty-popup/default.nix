{ config, pkgs, ... }:

let
  script = pkgs.writeShellApplication
    {
      name = "kitty-popup";

      runtimeInputs = with pkgs; [
        kitty
      ];

      text = builtins.readFile ./kitty-popup.sh;
    };

in
{
  home.packages = [
    script
  ];
}
