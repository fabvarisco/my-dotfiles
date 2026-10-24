{ self, nixpkgs, home-manager, vicinae, silentSDDM, ... } @inputs:

let
  defaultUser = {
    username = "fabvarisco";
    fullName = "Fabricio Varisco Oliveira";
    homeDirectory = "/home/fabvarisco";
  };

  mkHost = { hostname, desktop, user ? defaultUser, extraModules ? [] }:
    nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs user; };
      modules = [
        ./hosts/${hostname}/configuration.nix
        ./modules/desktop/${desktop}.nix
        silentSDDM.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${user.username} = { ... }: {
              imports = [
                ./home/common.nix
                ./home/${desktop}.nix
                ./home/cursor/aosp.nix
              ];
              home.username = user.username;
              home.homeDirectory = user.homeDirectory;
              home.stateVersion = "25.05";
            };
            backupFileExtension = "backup";
            extraSpecialArgs = { inherit inputs user; };
          };
        }
      ] ++ extraModules;
    };
in {
  nixosConfigurations = {
    beelink-hypr = mkHost {
      hostname = "beelink";
      desktop = "hyprland";
    };
  };
}
