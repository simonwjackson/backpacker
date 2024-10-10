{
  description = "Advanced example of Nix-on-Droid system config with home-manager.";

  inputs = {
    dnshack = {
      url = "github:simonwjackson/dnshack";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mountainous = {
      url = "github:simonwjackson/mountainous";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    secrets = {
      url = "github:simonwjackson/secrets";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-on-droid,
    mountainous,
    ...
  } @ inputs: let
    lib = nixpkgs.lib;

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

    homeManagerModules = findDefaultNix ./modules/home;
    nixOnDroidModules = findDefaultNix ./modules/nix-on-droid;

    homesDir = ./homes/aarch64-droid;
    systemsDir = ./systems/aarch64-droid;
    systemFiles = builtins.attrNames (builtins.readDir systemsDir);
    systemNames = map (file: builtins.head (builtins.split "\\." file)) systemFiles;

    mkNixOnDroidConfiguration = name:
      nix-on-droid.lib.nixOnDroidConfiguration {
        modules =
          [
            (systemsDir + "/${name}")
            {
              home-manager = {
                config = homesDir + "/nix-on-droid@${name}/default.nix";
                extraSpecialArgs = {inherit inputs;};
                backupFileExtension = "hm-bak";
                useGlobalPkgs = true;
                sharedModules =
                  # builtins.attrValues (builtins.removeAttrs inputs.mountainous.homeModules ["_default"])
                  homeManagerModules
                  ++ [
                    inputs.mountainous.homeModules.eza
                    inputs.mountainous.homeModules.agenix
                    inputs.mountainous.homeModules.atuin
                    inputs.mountainous.homeModules.git
                    inputs.mountainous.homeModules.lf
                    inputs.mountainous.inputs.agenix.homeManagerModules.age
                  ];
              };
            }
          ]
          ++ nixOnDroidModules;

        extraSpecialArgs = {
          inherit inputs;
        };

        pkgs = import nixpkgs {
          system = "aarch64-linux";

          overlays = [
            nix-on-droid.overlays.default
          ];
        };

        home-manager-path = home-manager.outPath;
      };
  in {
    nixOnDroidConfigurations = builtins.listToAttrs (map (name: {
        inherit name;
        value = mkNixOnDroidConfiguration name;
      })
      systemNames);
  };
}
