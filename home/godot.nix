{ config, lib, pkgs, ... }:

let
  # Cursor Dark (the IDE default). Godot only exposes base, accent and contrast
  # for the chrome; the script colors live in the .tet theme.
  cursorBase = "Color(0.078431, 0.078431, 0.078431, 1)";
  cursorAccent = "Color(0.533333, 0.752941, 0.815686, 1)";
  cursorBin = "/run/current-system/sw/bin/cursor";
  cursorFlags = "{project} --goto {file}:{line}:{col}";
in
{
  home.file.".config/godot/text_editor_themes/Cursor Dark.tet".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/Developer/my-dotfiles/config/godot/Cursor Dark.tet";

  # editor_settings is rewritten by the editor, so only these keys are pinned.
  home.activation.godotCursorTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.config/godot/editor_settings-4.7.tres"
    if [ -f "$settings" ]; then
      ${pkgs.gnused}/bin/sed -i \
        -e 's|^interface/theme/color_preset = .*|interface/theme/color_preset = "Custom"|' \
        -e 's|^interface/theme/base_color = .*|interface/theme/base_color = ${cursorBase}|' \
        -e 's|^interface/theme/accent_color = .*|interface/theme/accent_color = ${cursorAccent}|' \
        -e 's|^interface/theme/contrast = .*|interface/theme/contrast = 0.12|' \
        -e 's|^interface/theme/corner_radius = .*|interface/theme/corner_radius = 6|' \
        -e 's|^interface/theme/icon_saturation = .*|interface/theme/icon_saturation = 1.0|' \
        -e 's|^text_editor/theme/color_theme = .*|text_editor/theme/color_theme = "Cursor Dark"|' \
        -e 's|^text_editor/external/exec_path = .*|text_editor/external/exec_path = "${cursorBin}"|' \
        -e 's|^text_editor/external/exec_flags = .*|text_editor/external/exec_flags = "${cursorFlags}"|' \
        -e 's|^text_editor/external/use_external_editor = .*|text_editor/external/use_external_editor = true|' \
        "$settings"
    fi
  '';
}
