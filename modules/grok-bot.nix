{ lib, fetchurl, appimageTools, makeWrapper }:

let
  pname = "grok-bot";
  version = "0.78.1";
  src = fetchurl {
    url = "https://downloads.cursor.com/grokbot/stable/72e130b4e6be3fdc47b97e809b6b420908ce2dd8/linux/x64/Grok_Bot_${version}.AppImage";
    hash = "sha256-BQ11I8bvoEYmYROuLjsfPOlAlVSSwrlS/T5pi2DXP7g=";
  };
  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  nativeBuildInputs = [ makeWrapper ];

  extraInstallCommands = ''
    desktop=$(find ${appimageContents} -name '*.desktop' -print -quit)
    install -m 444 -D "$desktop" $out/share/applications/grok-bot.desktop
    sed -i 's|^Exec=.*|Exec=grok-bot --no-sandbox %U|' $out/share/applications/grok-bot.desktop
    sed -i 's|^Name=.*|Name=Grok Bot|' $out/share/applications/grok-bot.desktop

    icon=$(find ${appimageContents} -name '*.png' -path '*512*' -print -quit || true)
    if [ -z "$icon" ]; then
      icon=$(find ${appimageContents} -name '*.png' -print -quit || true)
    fi
    if [ -n "$icon" ]; then
      install -m 444 -D "$icon" $out/share/icons/hicolor/512x512/apps/grok-bot.png
      sed -i 's|^Icon=.*|Icon=grok-bot|' $out/share/applications/grok-bot.desktop
    fi

    wrapProgram $out/bin/grok-bot \
      --add-flags "--ozone-platform-hint=auto"
  '';

  meta = {
    description = "Grok Bot desktop app";
    mainProgram = "grok-bot";
    homepage = "https://cursor.com/download/bot";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
