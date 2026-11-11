{
  description = "Setup WSL2 reprodutível do Hitsu (Ubuntu + Nix + home-manager + devenv)";

  inputs = {
    # nixpkgs-unstable: pacotes novos (claude-code, codex, opencode, herdr, zed...).
    # Versão travada no flake.lock -> só muda quando VOCÊ rodar `nix flake update`.
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
        # claude-code (e outros) têm licença não-livre.
        config.allowUnfree = true;
      };
    in
    {
      homeConfigurations.${user.username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit user; };
        modules = [ ./home.nix ];
      };

      # `nix run .#home-manager -- switch --flake .` usa o home-manager travado no lock.
      packages.${system} = {
        home-manager = home-manager.packages.${system}.default;
        default = home-manager.packages.${system}.default;
      };

      formatter.${system} = pkgs.nixfmt;
    };
}
