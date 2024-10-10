{
  inputs = {
    mountainous = {
      url = "github:simonwjackson/mountainous";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    secrets = {
      url = "github:simonwjackson/secrets";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs = inputs: let
    nixOnDroidOutputs.nixOnDroidConfigurations = let
      systemsDir = ./systems/aarch64-droid;
      systemFiles = builtins.attrNames (builtins.readDir systemsDir);
      systemNames = map (file: builtins.head (builtins.split "\\." file)) systemFiles;

      homeManagerDroid = {
        home-manager = {
          extraSpecialArgs = {inherit inputs;};
          backupFileExtension = "hm-bak";
          useGlobalPkgs = true;
          config = {lib, ...}: {
            imports =
              (builtins.attrValues inputs.mountainous.homeModules)
              # ++ [
              #   # Include all backpacker NixOS modules
              #   inputs.mountainous.homeModules.eza # Add this line to import the eza module
              # ]
              ++ (
                let
                  # Function to find default.nix files, stopping at each found default.nix
                  findDefaultNix = dir: let
                    contents = builtins.readDir dir;
                    hasDefaultNix = builtins.hasAttr "default.nix" contents && contents."default.nix" == "regular";
                  in
                    if hasDefaultNix
                    then [(dir + "/default.nix")]
                    else let
                      subdirs = lib.filterAttrs (n: v: v == "directory") contents;
                      subdirPaths = map (n: dir + "/${n}") (builtins.attrNames subdirs);
                    in
                      lib.concatMap findDefaultNix subdirPaths;
                in
                  findDefaultNix ./modules/home
              );
          };
        };
      };

      mkConfig = name:
        inputs.nix-on-droid.lib.nixOnDroidConfiguration {
          pkgs = import inputs.nixpkgs {system = "aarch64-linux";};
          modules = [
            (systemsDir + "/${name}")
            homeManagerDroid
            {
              home-manager.config = import (./homes/aarch64-droid + "/nix-on-droid@${name}");
            }
          ];
        };
    in
      builtins.listToAttrs (
        map
        (name: {
          inherit name;
          value = mkConfig name;
        })
        systemNames
      );
  in
    nixOnDroidOutputs;
}
