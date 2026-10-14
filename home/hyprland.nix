{ config, pkgs, lib, user, ... }:

{
  imports = [
    ./nautilus.nix
    ./vicinae.nix
    ./noctalia.nix
    ./cursor/aosp.nix
  ];

  home.packages = with pkgs; [
    # File managers (Hyprland exclusive)
    nautilus
    yazi

    # Hyprland ecosystem
    hyprlock
    hypridle
    hyprmon
    hyprpolkitagent

    # Notifications
    libnotify

    # Sound effects (pw-play is provided by pipewire, already in system packages)
    kdePackages.oxygen-sounds

    # Brightness control
    brightnessctl

    # Audio
    pwvucontrol
    playerctl

    # Bluetooth
    blueman

    # Monitor auto-detection (for hyprmon-watch)
    socat
    jq
  ];

  # Hyprland 0.55+ prefers hyprland.lua and ignores hyprland.conf when both exist.
  # force replaces the example file Hyprland generates on first launch.
  home.file.".config/hypr/hyprland.lua" = {
    force = true;
    text =
      builtins.replaceStrings [ "@USERNAME@" ] [ user.username ]
      (builtins.readFile ../config/hyprland/hyprland.lua);
  };

  home.file.".config/hypr/hypridle.conf".source = ../config/hyprland/hypridle.conf;
  home.file.".config/hypr/hyprlock.conf".source = ../config/hyprland/hyprlock.conf;

  home.file.".config/hypr/battery-manager.sh" = {
    source = ../config/hyprland/battery-manager.sh;
    executable = true;
  };
  home.file.".config/hypr/gpu-screen.sh" = {
    source = ../config/hyprland/gpu-screen.sh;
    executable = true;
  };
  home.file.".config/hypr/mouse-sensitivity.sh" = {
    source = ../config/hyprland/mouse-sensitivity.sh;
    executable = true;
  };
  home.file.".config/hypr/wallpaper-vicinae.sh" = {
    source = ../config/hyprland/wallpaper-vicinae.sh;
    executable = true;
  };

  # Seed monitors.conf on first activation; hyprmon writes profiles here.
  # Not Nix-managed after creation — persists across rebuilds.
  home.activation.createMonitorsConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/hypr"
    if [ ! -f "$HOME/.config/hypr/monitors.conf" ]; then
      cat > "$HOME/.config/hypr/monitors.conf" << 'MONITORSEOF'
# Laptop display (ThinkPad eDP-1)
monitor = eDP-1, 1920x1200@60, auto, 1.0

# Dell P3425WE ultrawide
monitor = desc:Dell Inc. DELL P3425WE, 3440x1440@100, 0x0, 1.0

# Fallback for other external monitors
monitor = , preferred, auto, 1.0
MONITORSEOF
    fi
  '';
  # Polkit authentication agent (needed by NetworkManager wifi connect, hyprlock, etc)
  systemd.user.services.hyprpolkitagent = {
    Unit = {
      Description = "Hyprland polkit authentication agent";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Restart = "on-failure";
      RestartSec = "5";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
