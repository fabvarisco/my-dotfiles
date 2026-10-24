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
    godotPackages_4_5.godot
    godot_4-mono
    code-cursor
    f3d
  ];
}
