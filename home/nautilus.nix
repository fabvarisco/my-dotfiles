{ config, lib, pkgs, ... }:

let
  papirus-dark-nordic = pkgs.papirus-icon-theme.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.gawk ];
    postInstall = (old.postInstall or "") + ''
      export XDG_DATA_HOME="$out/share"
      export USER_HOME="$out"
      export XDG_CONFIG_HOME="$(mktemp -d)"
      ${pkgs.papirus-folders}/bin/papirus-folders -C nordic -t Papirus-Dark
    '';
  });
in
{
  home.packages = with pkgs; [
    nautilus-open-any-terminal
  ];

  # GTK theme e configurações
  gtk = {
    enable = true;

    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };

    # Keep GTK4 apps following the GTK theme (legacy default pre-26.05)
    gtk4.theme = config.gtk.theme;

    iconTheme = {
      name = "Papirus-Dark";
      package = papirus-dark-nordic;
    };

    gtk3.bookmarks = [
      "file://${config.home.homeDirectory}/Downloads Downloads"
      "file://${config.home.homeDirectory}/Developer Developer"
      "file://${config.home.homeDirectory}/Documents Documents"
      "file://${config.home.homeDirectory}/Videos Videos"
      "file://${config.home.homeDirectory}/Images Images"

    ];
  };

  # Preferências do Nautilus via dconf
  dconf.settings = {
    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
      show-hidden-files = true;
      default-sort-order = "name";
      default-sort-in-reverse-order = false;
      show-delete-permanently = true;
    };

    "org/gnome/nautilus/list-view" = {
      default-column-order = ["name" "size" "type" "date_modified"];
      default-visible-columns = ["name" "size" "date_modified"];
      use-tree-view = false;
    };

    "org/gnome/nautilus/window-state" = {
      initial-size = lib.gvariant.mkTuple [(lib.gvariant.mkInt32 1200) (lib.gvariant.mkInt32 700)];
      maximized = false;
      sidebar-width = lib.gvariant.mkInt32 200;
    };

    "org/gnome/nautilus/icon-view" = {
      default-zoom-level = "small";
    };

    "com/github/stunkymonkey/nautilus-open-any-terminal" = {
      terminal = "kitty";
      new-tab = false;
      keybinding = "<Ctrl><Alt>t";
    };
  };

  home.activation.nautilusFolderIcons =
    let
      home = config.home.homeDirectory;
      folderIcons = {
        "${home}/Developer" = "folder-nordic-development";
        "${home}/Downloads" = "folder-nordic-downloads";
        "${home}/Documents" = "folder-nordic-documents";
        "${home}/Videos"    = "folder-nordic-videos";
        "${home}/Images"    = "folder-nordic-pictures";
      };
      setCmds = lib.concatStringsSep "\n" (lib.mapAttrsToList (dir: icon: ''
        if [ -d "${dir}" ]; then
          # gvfs metadata is not available this early in boot. A failure here
          # aborts the rest of home-manager activation.
          run ${pkgs.glib}/bin/gio set "${dir}" metadata::custom-icon-name '${icon}' || true
        fi
      '') folderIcons);
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] setCmds;
}
