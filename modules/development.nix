{ pkgs, ... }:

{

  environment.systemPackages = with pkgs; [
    git
    wget
    gh
    vscode
    nodejs_24
    claude-code
    codex
    cursor-cli
    fastfetch
    kitty
    starship
    godotPackages_4_7.godot
    code-cursor
    f3d
    (callPackage ./grok-bot.nix { })
  ];
}
