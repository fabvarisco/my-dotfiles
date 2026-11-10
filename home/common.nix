{ config, pkgs, ... }:

{
  imports = [ ./godot.nix ];
  home.packages = with pkgs; [
    # Qt/GTK theming
    kdePackages.breeze
    kdePackages.breeze-icons
    adwaita-icon-theme

    # Screen recording
    simplescreenrecorder

    # Social
    vesktop
  ];

  # Vicinae (and other launchers) pick this over the package desktop entry.
  # --classic forces the IDE window instead of glass / Agents Window.
  xdg.enable = true;
  xdg.desktopEntries.cursor = {
    name = "Cursor";
    genericName = "Text Editor";
    comment = "Code Editing. Redefined.";
    exec = "cursor --classic %F";
    icon = "cursor";
    categories = [ "Utility" "TextEditor" "Development" "IDE" ];
    mimeType = [
      "application/x-cursor-workspace"
      "application/x-code-workspace"
      "text/plain"
      "inode/directory"
    ];
    startupNotify = true;
    settings = {
      StartupWMClass = "cursor";
      Keywords = "vscode";
      Version = "1.5";
    };
    actions.new-empty-window = {
      name = "New Empty Window";
      exec = "cursor --classic --new-window %F";
      icon = "cursor";
    };
  };

  # Shared configs
  home.file.".config/kitty".source = ../config/shared/kitty;
  home.file.".config/btop".source = ../config/shared/btop;
  home.file.".config/starship.toml".source = ../config/shared/starship.toml;
  home.file.".config/fastfetch".source = ../config/shared/fastfetch;
  home.file.".config/walls".source = ../config/walls;
  home.file.".config/profile-pics".source = ../config/profile-pics;
  home.file.".claude/skills".source = ../config/agentskills;
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/Developer/my-dotfiles/config/shared/nvim";
  home.file.".config/onedrive/config".text = ''
    disable_notifications = "true"
  '';

  # Bash
  programs.bash = {
    enable = true;
    initExtra = ''
      eval "$(starship init bash)"
      bash ~/.config/fastfetch/random-logo.sh
    '';
  };
}
