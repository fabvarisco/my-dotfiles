{
  description = "hyprland";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
      "https://zen-browser.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCUSjDg="
      "zen-browser.cachix.org-1:nocWVkADxTz+7HyJHRXbD3xKUCerRiAKjFxGQKQ6V4g="
    ];
  };

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
      flake = false;
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia/legacy-v4";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    silentSDDM = {
      url = "git+https://github.com/uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "https://github.com/0xc000022070/zen-browser-flake/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr = {
      url = "git+https://github.com/ogulcancelik/herdr?rev=87e5c13c6028df72405f63388dde585212ad3019";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:  import ./outputs.nix inputs;
}
