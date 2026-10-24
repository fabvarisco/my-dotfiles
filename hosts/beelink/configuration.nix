{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
  ];

  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  
  networking.hostName = "beelink";
  programs.nix-ld.enable = true; 
  hardware.graphics = {
    enable = true;
    enable32Bit = true; 
    
    extraPackages = with pkgs; [
      libva-utils
      rocmPackages.clr.icd 
    ];
  };


  # Power profiles (consumed by noctalia power-profile widget; no TLP on this host)
  services.power-profiles-daemon.enable = true;

  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; 
    dedicatedServer.openFirewall = true; 
    localNetworkGameTransfers.openFirewall = true;
  };

  # AMD GPU: Vulkan via RADV, VA-API via radeonsi
  environment.sessionVariables = {
    AMD_VULKAN_ICD = "RADV";
    LIBVA_DRIVER_NAME = "radeonsi";
  };

  environment.systemPackages = with pkgs; [
    inkscape
  ];

  system.stateVersion = "25.05";
}
