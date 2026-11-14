{ pkgs, lib, ... }:

{
  # Kernel mais responsivo sob carga (latency tweaks, scheduler diferente)
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_zen;

  # Engines modernos (Star Citizen, Hogwarts Legacy, alguns Unreal 5) pedem
  # mais do que o padrão NixOS (1048576)
  boot.kernel.sysctl."vm.max_map_count" = 2147483642;

  # Udev rules p/ Steam Controller, Steam Deck dock, dongles compat. Steam Input
  hardware.steam-hardware.enable = true;

  # Auto-priority de processos (cobre o que gamemoded não cobre)
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };

  # GPU Screen Recorder - capabilities for gsr-kms-server
  security.wrappers.gsr-kms-server = {
    owner = "root";
    group = "root";
    capabilities = "cap_sys_admin+ep";
    source = "${pkgs.gpu-screen-recorder}/bin/gsr-kms-server";
  };

  # Steam UI scaling for HiDPI monitors
  environment.sessionVariables = {
    STEAM_FORCE_DESKTOPUI_SCALING = "1.5";
  };

  environment.systemPackages = with pkgs; [
    pcsx2
    gpu-screen-recorder      # Replay buffer / recording (like NVIDIA ShadowPlay)
    gpu-screen-recorder-gtk  # GUI for gpu-screen-recorder
    mangohud                 # Overlay de FPS/stats (pressione R_Shift+F12 no jogo)
    goverlay                 # GUI p/ configurar MangoHud
    vkbasalt                 # Pós-processamento Vulkan (sharpen, CAS, FXAA)
    protonup-qt              # Gerenciar versões do Proton
    protontricks             # Troubleshoot/instalar deps em prefixes Proton
  ];

  programs.gamemode = {
    enable = true;
    settings.general = {
      renice = 10;
      inhibit_screensaver = 1;
    };
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  # Elgato Stream Deck (Linux). Installs the app and udev rules for vendor 0fd9.
  programs.streamcontroller.enable = true;

  services.flatpak.enable = true;
}
