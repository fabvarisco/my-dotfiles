{ pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    inputs.zen-browser.packages.${pkgs.system}.default
    gum
    unzip
    zip
    p7zip
    btop
    imv
    mpv
    vlc
    cava
    cmatrix
    tenki
    krabby
    teamspeak6-client
    protonvpn-gui
    wireguard-tools
  ];
}
