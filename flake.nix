{
  description = "Reproducible WSL2 setup (Ubuntu + Nix + home-manager + devenv)";

  inputs = {
    # nixpkgs-unstable: newer packages (claude-code, codex, opencode, herdr, zed...).
    # Pinned in flake.lock -> it changes only when you run `nix flake update`.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      user = import ./user.nix;
      system = user.system;
      pkgs = import nixpkgs {
        inherit system;
        # claude-code (and others) are unfree.
        config.allowUnfree = true;
      };
    in
    {
      homeConfigurations.${user.username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit user; };
        modules = [ ./home.nix ];
      };

      # `nix run .#home-manager -- switch --flake .` uses the home-manager pinned in the lock.
      packages.${system} = {
        home-manager = home-manager.packages.${system}.default;
        default = home-manager.packages.${system}.default;
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
