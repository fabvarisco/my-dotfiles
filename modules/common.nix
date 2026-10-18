{ config, pkgs, lib, inputs, user, ... }:

{
  imports = [
    ./development.nix
    ./gaming.nix
    ./utils.nix
    ./fonts.nix
    ../users/default.nix
  ];

  # waydroid 
  virtualisation.waydroid = {
    enable = true;
    package = pkgs.waydroid-nftables;
  };

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.networkmanager.enable = true;

  # Power & battery (needed by noctalia battery widget)
  services.upower.enable = true;

  # Timezone & locale
  time.timeZone = "America/Sao_Paulo";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  # onedrive
  services.onedrive.enable = true;

  services.xserver.xkb.layout = "us";
  services.xserver.xkb.variant = "";
  console.keyMap = "us";

  # libinput
  services.libinput.enable = true;

  # USB auto mount
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # SDDM with SilentSDDM theme
  services.xserver.enable = true;
  programs.silentSDDM = {
    enable = true;
    theme = "rei";  # Options: rei, ken, silvia
    profileIcons.${user.username} = ../config/profile-pics/profile_2.jpg;
  };

  # Audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # GTK Dark
  nixpkgs.config.allowUnfree = true;
  environment.sessionVariables = {
    GTK_THEME = "Adwaita:dark";
    # Electron apps (Discord, VSCode, etc) - native Wayland
    NIXOS_OZONE_WL = "1";
  };

  programs.dconf = {
    enable = true;
    profiles.user.databases = [{
      settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          gtk-theme = "Adwaita-dark";
        };
      };
    }];
  };

  programs.firefox.enable = true;

  # Nix settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [
      "https://cache.nixos.org"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCUSjDg="
    ];
  };
}
