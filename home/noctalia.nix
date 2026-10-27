{ inputs, config, lib, pkgs, ... }:

{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia-shell.enable = true;

  # Qt 6.12 registers a QtQuick.Color singleton that shadows qs.Commons.Color.
  # The bare import stays so Settings, Style and Logger keep resolving.
  # Palette access goes through the alias, which cannot see QtQuick.Color.
  # Style.qml lives inside qs.Commons and uses the sibling singleton, so it
  # pins QtQuick 6.11 instead of importing its own module.
  programs.noctalia-shell.package =
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        find . -name '*.qml' -print0 | while IFS= read -r -d "" f; do
          if grep -qx 'import qs.Commons' "$f"; then
            sed -i \
              -e '/^import qs\.Commons$/a import qs.Commons as Commons' \
              -e 's/\([^[:alnum:]_.]\)Color\./\1Commons.Color./g' \
              -e 's/^Color\./Commons.Color./' \
              "$f"
          elif grep -q 'Color\.' "$f"; then
            sed -i 's/^import QtQuick$/import QtQuick 6.11/' "$f"
          fi
        done

        # Boot race: property writes while the first read is in flight start a
        # save 500ms later. That save cancels the read, onLoaded never runs,
        # and the bar never appears when login is busy. Ignore those writes
        # until the file has loaded, then allow migrations to persist.
        sed -i \
          -e 's/onAdapterUpdated: saveTimer.start()/onAdapterUpdated: if (root.isLoaded) saveTimer.start()/' \
          Commons/Settings.qml
        sed -i \
          '/Logger.i("Settings", "Settings loaded");/a\        root.isLoaded = true;' \
          Commons/Settings.qml
        sed -i \
          '/\/\/ Emit the signal/{n; /root.isLoaded = true;/d;}' \
          Commons/Settings.qml
      '';
    });

  # Direct symlink into the repo. mkOutOfStoreSymlink points at a symlink in
  # the nix store, and quickshell follows only one link when saving, so the
  # write lands on a read-only store path and fails.
  # Edita pela UI do noctalia; muda o arquivo no repo; commit + pull sincroniza.
  home.activation.linkNoctaliaSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    mkdir -p "$HOME/.config/noctalia"
    ln -sfn "${config.home.homeDirectory}/Developer/my-dotfiles/config/shared/noctalia/settings.json" \
      "$HOME/.config/noctalia/settings.json"
  '';

  # hyprland.start only runs once. After resume the shell can exit when the
  # output disappears, and nothing brings it back. The service restarts on
  # crash; hypridle restarts it after sleep if the bar layers are gone.
  systemd.user.services.noctalia-shell = {
    Unit = {
      Description = "Noctalia shell";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      StartLimitIntervalSec = "30";
      StartLimitBurst = "5";
    };

    Service = {
      Type = "simple";
      ExecStart = "${config.programs.noctalia-shell.package}/bin/noctalia-shell";
      Restart = "on-failure";
      RestartSec = "3";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
