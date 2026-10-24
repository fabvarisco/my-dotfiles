{ config, pkgs, lib, ... }:

let
  # Zen Browser is not in nixpkgs. This community flake commit
  # installs the beta binary instead of building Firefox.
  zen-browser =
    (import
      (builtins.fetchTarball {
        url = "https://github.com/0xc000022070/zen-browser-flake/archive/f19490ac889eabb05bdb7e8dcb85225ee75bd87b.tar.gz";
        sha256 = "1ymsgq6vjvd683cxn4pc92nqfvkj6kkm7rn9c6h57cj3wb9c8zwh";
      })
      { inherit pkgs; }
    ).default;

  cachyos-src = pkgs.fetchFromGitHub {
    owner = "numb747";
    repo = "cachyOS-config";
    rev = "9eb3669e47a67cffdac4e4877e5d2d999168c69e";
    hash = "sha256-iIREO5Yga3QeOBXQjqEogvrsJhoYoIDs27IQketNqQ0=";
  };

  # Images only. The tokyonight directory in that repo is a generator script.
  cachyos-wallpapers = pkgs.runCommand "cachyos-wallpapers" { } ''
    mkdir -p "$out"
    cd ${cachyos-src}/wallpaper
    find . -type f \( \
      -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o \
      -iname '*.webp' -o -iname '*.jxl' \
    \) -print0 | while IFS= read -r -d "" file; do
      dest="$out/$file"
      mkdir -p "$(dirname "$dest")"
      cp -a "$file" "$dest"
    done
  '';
in
{
  # -------------------------------------------------------------------
  # 1. USER
  # -------------------------------------------------------------------
  home.username = "fabvarisco";
  home.homeDirectory = "/home/fabvarisco";

  # Do not change this. It selects the Home Manager state version.
  home.stateVersion = "24.11"; 

  # -------------------------------------------------------------------
  # 2. NIXPKGS
  # -------------------------------------------------------------------
  # Required to install Cursor, which is unfree.
  nixpkgs.config.allowUnfree = true;

  # -------------------------------------------------------------------
  # 3. PACKAGES
  # -------------------------------------------------------------------
  fonts.fontconfig.enable = true;

  # Noctalia's Nix build looks for EGL under /run/opengl-driver, which
  # exists on NixOS and not on Fedora. Point it at Nix's Mesa instead.
  home.packages = with pkgs; [
    noctalia
    (writeShellScriptBin "noctalia-session" ''
      export __EGL_VENDOR_LIBRARY_FILENAMES="${mesa}/share/glvnd/egl_vendor.d/50_mesa.json"
      export LIBGL_DRIVERS_PATH="${mesa}/lib/dri"
      # Canoas, RS. The system zone stays America/New_York until timedatectl is used.
      export TZ="''${TZ:-America/Sao_Paulo}"
      # Nix curl does not see Fedora's CA store, so city lookup fails.
      export SSL_CERT_FILE="''${SSL_CERT_FILE:-${cacert}/etc/ssl/certs/ca-bundle.crt}"
      export CURL_CA_BUNDLE="$SSL_CERT_FILE"
      export NIX_SSL_CERT_FILE="$SSL_CERT_FILE"
      exec ${noctalia}/bin/noctalia "$@"
    '')
    nerd-fonts.jetbrains-mono
    # SwayFX without the nixpkgs session wrapper. Fedora's start-sway already starts the session.
    (swayfx.override { withBaseWrapper = false; isNixOS = false; })
    # The Nix binary looks for EGL/GBM in /run/opengl-driver. The profile provides Mesa.
    mesa
    # Editors
    code-cursor
    cursor-cli
    zen-browser
    # Languages
    nodejs_22
    rustc
    cargo

    # Terminal tools
    fastfetch
    git
    gh
    kitty

    # Flat icons for Thunar. Tela-grey-dark is the monochrome dark variant.
    tela-icon-theme

    # Communication
    vesktop
    teamspeak6-client

    # Arrange Sway outputs. Writes ~/.config/sway/outputs.
    nwg-displays

    # Unfocused windows stay at 80% opacity. The focused window stays opaque.
    (writeShellScriptBin "inactive-opacity" ''
      exec ${python3}/bin/python3 ${./sway/inactive-opacity.py}
    '')

    # Mouse sensitivity: pointer-accel 0.3  (from -1.0 to 1.0)
    (writeShellScriptBin "pointer-accel" ''
      set -eu
      file="$HOME/.config/sway/pointer.conf"

      # Vicinae's service does not inherit SWAYSOCK from the compositor.
      if [ -z "''${SWAYSOCK:-}" ]; then
        sock=$(find "/run/user/$(id -u)" -maxdepth 1 -name 'sway-ipc.*.sock' -print -quit 2>/dev/null || true)
        if [ -n "$sock" ]; then
          export SWAYSOCK="$sock"
        fi
      fi

      if [ "''${1:-}" = "-h" ] || [ "''${1:-}" = "--help" ]; then
        echo "Usage: pointer-accel [VALUE]"
        echo "VALUE ranges from -1.0 (slower) to 1.0 (faster). 0 is the default."
        echo "With no VALUE, print the current acceleration of each pointer."
        exit 0
      fi

      if [ "$#" -eq 0 ]; then
        swaymsg -t get_inputs | python3 -c '
      import json, sys
      for dev in json.load(sys.stdin):
          libinput = dev.get("libinput") or {}
          speed = libinput.get("accel_speed")
          if dev.get("type") == "pointer" and speed is not None:
              print("%s: %s" % (dev.get("name"), speed))
      '
        exit 0
      fi

      if [ "$#" -ne 1 ]; then
        echo "Usage: pointer-accel [VALUE]" >&2
        exit 1
      fi

      value="$1"
      python3 -c '
      import sys
      try:
          value = float(sys.argv[1])
      except ValueError:
          sys.exit("Invalid value. Use a number from -1.0 to 1.0.")
      if value < -1.0 or value > 1.0:
          sys.exit("Value out of range. Use -1.0 to 1.0.")
      ' "$value"

      swaymsg "input type:pointer pointer_accel $value" >/dev/null
      mkdir -p "$(dirname "$file")"
      printf '%s\n' \
        '# pointer_accel ranges from -1.0 (slower) to 1.0 (faster).' \
        '# Change it with: pointer-accel 0.3' \
        'input type:pointer {' \
        "    pointer_accel $value" \
        '}' > "$file"
      echo "Mouse sensitivity: $value"
    '')
  ];

  # -------------------------------------------------------------------
  # 4. PROGRAM MODULES
  # -------------------------------------------------------------------

  # Vicinae launcher. The Nix package looks for the EGL driver in
  # /run/opengl-driver, which does not exist on Fedora.
  programs.vicinae = {
    enable = true;
    systemd = {
      enable = true;
      target = "sway-session.target";
    };
    settings = {
      theme.dark.name = "vicinae-dark";
      favorites = [
        "clipboard:history"
        "applications:cursor"
      ];
    };
  };

  # The Nix binary looks for EGL in /run/opengl-driver and does not see
  # .desktop files installed by Home Manager. The service needs both.
  systemd.user.services.vicinae.Service.Environment = [
    "__EGL_VENDOR_LIBRARY_FILENAMES=${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json"
    "LIBGL_DRIVERS_PATH=${pkgs.mesa}/lib/dri"
    "PATH=%h/.nix-profile/bin:/usr/local/bin:/usr/bin"
    "XDG_DATA_DIRS=%h/.nix-profile/share:/usr/local/share:/usr/share"
  ];

  # Fedora's ~/.bashrc reads ~/.bashrc.d before Nix is on PATH, so init
  # would use the store binary. The module integration stays off to avoid
  # a duplicate prompt.
  programs.starship = {
    enable = true;
    enableBashIntegration = false;
  };

  home.file.".bashrc.d/starship.sh".text = ''
    eval "$(${pkgs.starship}/bin/starship init bash)"
    PATH="$HOME/.nix-profile/bin:$PATH" bash "$HOME/.config/fastfetch/random-logo.sh"
  '';

  # -------------------------------------------------------------------
  # 5. NOCTALIA, SWAY, FASTFETCH, AND KITTY
  # -------------------------------------------------------------------
  # Noctalia is the bar. Fedora's Waybar is not started.
  xdg.configFile = let
    swayDropins = ./sway/config.d;
    dropinNames = builtins.attrNames (builtins.readDir swayDropins);
  in builtins.listToAttrs (map (name: {
    name = "sway/config.d/${name}";
    value.source = swayDropins + "/${name}";
  }) dropinNames) // {
    "noctalia/config.toml".source = ./noctalia/config.toml;
    "noctalia/palettes/cursor-dark.json".source = ./noctalia/palettes/cursor-dark.json;
    "noctalia/palettes/mono.json".source = ./noctalia/palettes/mono.json;
    "sway/config".source = ./sway/config;
    "sway/environment".source = ./sway/environment;
    "swaylock/config".source = ./swaylock/config;
    "fastfetch" = {
      source = ./fastfetch;
      recursive = true;
    };
    "kitty" = {
      source = ./kitty;
      recursive = true;
    };
    "starship.toml".source = ./starship.toml;
    # Thunar is GTK 3. Adwaita dark for the widgets, Tela grey for the icons.
    "gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-application-prefer-dark-theme=1
      gtk-theme-name=Adwaita
      gtk-icon-theme-name=Tela-grey-dark
    '';
  };

  # GTK looks in ~/.local/share/icons, not ~/.config. The session does not
  # always have the Nix profile on XDG_DATA_DIRS, so the theme is linked here.
  xdg.dataFile."icons/Tela-grey-dark".source = "${pkgs.tela-icon-theme}/share/icons/Tela-grey-dark";

  # GTK 3 on Fedora takes the icon theme from dconf, not settings.ini.
  dconf.settings."org/gnome/desktop/interface".icon-theme = "Tela-grey-dark";

  home.file."Pictures/Wallpapers".source = cachyos-wallpapers;

  xdg.dataFile."vicinae/scripts/set-mouse-sensitivity.sh" = {
    source = ./vicinae/set-mouse-sensitivity.sh;
    executable = true;
  };

  # nwg-displays and pointer-accel write these files. They stay outside
  # the Nix store so they remain editable after a switch.
  home.activation.seedSwayLocalConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/sway"
    if [ ! -e "$HOME/.config/sway/outputs" ]; then
      touch "$HOME/.config/sway/outputs"
    fi
    if [ ! -e "$HOME/.config/sway/workspaces" ]; then
      touch "$HOME/.config/sway/workspaces"
    fi
    if [ ! -e "$HOME/.config/sway/pointer.conf" ]; then
      cat > "$HOME/.config/sway/pointer.conf" << 'EOF'
# pointer_accel ranges from -1.0 (slower) to 1.0 (faster).
# Change it with: pointer-accel 0.3
input type:pointer {
    pointer_accel 0.0
}
EOF
    fi
  '';

  # -------------------------------------------------------------------
  # 6. HOME MANAGER
  # -------------------------------------------------------------------
  # Let Home Manager manage itself.
  programs.home-manager.enable = true;
}
