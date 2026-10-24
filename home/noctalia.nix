{ inputs, config, pkgs, ... }:

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
      '';
    });

  # settings.json gerenciado fora do store (gravável) -> versionado no repo.
  # Edita pela UI do noctalia; muda o arquivo no repo; commit + pull sincroniza.
  home.file.".config/noctalia/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/Developer/my-dotfiles/config/shared/noctalia/settings.json";
}
