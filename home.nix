# ============================================================================
#  home.nix — everything that is "yours" in WSL: packages, shell, git, editors, AIs.
#  After editing:  hms
#  (shortcut for `home-manager switch --flake <clone folder>`).
#  The folder is NOT fixed: bootstrap.sh records the path in
#  ~/.local/share/wsl-nix/flake-dir and zsh reads that file.
# ============================================================================
{
  config,
  pkgs,
  lib,
  user,
  ...
}:

let
  herdrPlugins = import ./herdr-plugins.nix { inherit pkgs; };
in
{
  home.username = user.username;
  home.homeDirectory = "/home/${user.username}";

  # Home Manager state-format version. Do not change it after the first switch
  # (it has nothing to do with package versions).
  home.stateVersion = "26.05";

  # Ubuntu is not NixOS: this adjusts XDG_DATA_DIRS, locale, and so on.
  targets.genericLinux.enable = true;
  # No GPU in WSL (Nix packages here do not need OpenGL/CUDA drivers).
  targets.genericLinux.gpu.enable = false;

  # --------------------------------------------------------------------------
  # Packages
  # --------------------------------------------------------------------------
  home.packages = (with pkgs; [
    # --- Everyday CLI ---
    ripgrep
    fd
    jq
    curl
    wget
    unzip
    zip
    tree
    htop
    wsl-open # open links/files in Windows' default browser/app (AI logins)

    # --- Agent multiplexer (REQUIRED) ---
    # herdr: "the runtime your coding agents live on" — https://github.com/herdrdev/herdr
    # Packaged in nixpkgs (pkgs/by-name/he/herdr).
    herdr

    # --- Coding AIs (all from nixpkgs-unstable) ---
    claude-code # comando: claude   (unfree -> allowUnfree no flake.nix)
    codex # comando: codex    (OpenAI Codex CLI)
    opencode # comando: opencode

    # --- Global languages (fallback; use devenv per project) ---
    nodejs_26 # Node 26 = LTS ativa ("Lithium") desde out/2026
    python3
    uv # fast Python manager (venv, pip, python versions)

    # --- Editors ---
    neovim # nvim / vi / vim (aliases below)

    # --- Per-project environments ---
    devenv

    # --- Nix: formatter + LSP (useful in Zed/Neovim while editing this repo) ---
    nixfmt
    nil

    # --- Zed INSIDE WSL (via WSLg) — left off on purpose.
    # Recommended: native Windows Zed + "Open WSL" (see the README).
    # Uncomment if you want to run Linux Zed through WSLg:
    # zed-editor

    # fastfetch comes from programs.fastfetch (do not list it again here).
    # starship comes from programs.starship.
  ]) ++ [
    # Plugin binaries (herdr itself calls the copy inside the plugin root).
    (pkgs.writeShellScriptBin "herdr-gitview" ''
      export PATH="$HOME/.nix-profile/bin:$PATH"
      exec ${herdrPlugins.herdr-gitview}/bin/herdr-gitview "$@"
    '')
    (pkgs.writeShellScriptBin "herdr-nvim" ''
      exec ${herdrPlugins.herdr-nvim}/bin/herdr-nvim "$@"
    '')
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    BROWSER = "wsl-open"; # claude/codex/opencode/gh open login in the Windows browser
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  # --------------------------------------------------------------------------
  # Shell: zsh + starship + fastfetch
  # Starship and fastfetch came from the fedora/sway branch.
  # Starship is managed ONLY by programs.starship (there is no xdg.configFile
  # and no manual eval in zsh — that would duplicate the prompt).
  # fastfetch: the package comes from the module; the files (config, ASCII, script)
  # come from xdg.configFile. programs.fastfetch.settings stays empty on
  # purpose, otherwise the module also generates config.jsonc and fights the directory.
  # --------------------------------------------------------------------------
  programs.zsh = {
    enable = true;
    autocd = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      share = true;
    };

    # Put Nix on PATH even if /etc/zsh/zshenv does not load the profile.
    # HM_FLAKE_DIR follows the folder bootstrap.sh ran in.
    envExtra = ''
      if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ] && [ -z "$__ETC_PROFILE_NIX_SOURCED" ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi
      if [ -f "$HOME/.local/share/wsl-nix/flake-dir" ]; then
        IFS= read -r HM_FLAKE_DIR < "$HOME/.local/share/wsl-nix/flake-dir"
        export HM_FLAKE_DIR
      fi
    '';

    # hms/hmu are functions (the flake folder is not fixed). fastfetch runs
    # at the end of zshrc, the way Fedora's bash ran random-logo.sh.
    initContent = lib.mkMerge [
      (lib.mkOrder 1000 ''
        hm-flake-dir() {
          local dir="''${HM_FLAKE_DIR:-}"
          if [[ -z $dir && -f $HOME/.local/share/wsl-nix/flake-dir ]]; then
            IFS= read -r dir < "$HOME/.local/share/wsl-nix/flake-dir"
          fi
          if [[ -z $dir || ! -d $dir ]]; then
            echo "Could not find the flake. Run ./bootstrap.sh from the clone (it writes ~/.local/share/wsl-nix/flake-dir)." >&2
            return 1
          fi
          printf '%s\n' "$dir"
        }
        # Covers an upstream Nix that has not enabled flakes yet. The same
        # line is written to nix.conf by bootstrap.sh for later shells.
        with_nix_flakes() {
          NIX_CONFIG="''${NIX_CONFIG:+$NIX_CONFIG$'\n'}experimental-features = nix-command flakes" \
            "$@"
        }
        hms() {
          local dir
          dir="$(hm-flake-dir)" || return
          with_nix_flakes home-manager switch --flake "$dir"
        }
        hmu() {
          local dir
          dir="$(hm-flake-dir)" || return
          with_nix_flakes nix --extra-experimental-features 'nix-command flakes' flake update --flake "$dir" \
            && with_nix_flakes home-manager switch --flake "$dir"
        }
      '')
      (lib.mkOrder 1500 ''
        if [[ $TERM != "dumb" && -x "$HOME/.config/fastfetch/random-logo.sh" ]]; then
          PATH="$HOME/.nix-profile/bin:$PATH" "$HOME/.config/fastfetch/random-logo.sh"
        fi
      '')
    ];

    shellAliases = {
      ls = "eza --group-directories-first";
      ll = "eza -lah --git --group-directories-first";
      lt = "eza --tree --level=2";
      g = "git";
      # `lg` stays the programs.lazygit function (cd on exit). An alias
      # with the same name would hide that function.
      v = "nvim";
      vi = "nvim";
      vim = "nvim";
      # Open the current folder in Windows Explorer
      explorer = "explorer.exe .";
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    # settings from starship.toml (fedora/sway), plus this setup's nix_shell.
    settings = lib.recursiveUpdate (builtins.fromTOML (builtins.readFile ./starship.toml)) {
      nix_shell.format = "via [❄️ $state( \\($name\\))]($style) ";
    };
  };

  programs.fastfetch.enable = true;

  xdg.configFile."fastfetch" = {
    source = ./fastfetch;
    recursive = true;
  };

  # direnv + nix-direnv: enter the project folder -> devenv loads on its own
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    config.global = {
      hide_env_diff = true;
      warn_timeout = "1m";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --exclude .git";
  };

  programs.zoxide = {
    enable = true; # `z folder` jumps to recently used directories
    enableZshIntegration = true;
  };

  programs.bat.enable = true;

  programs.eza = {
    enable = true;
    git = true;
    icons = "auto";
  };

  # --------------------------------------------------------------------------
  # Git
  # --------------------------------------------------------------------------
  programs.git = {
    enable = true;
    settings = {
      user.name = user.fullName;
      user.email = user.email;
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.autocrlf = "input"; # avoid the CRLF mess coming from Windows
      rerere.enabled = true;
    };
    ignores = [
      ".direnv/"
      ".devenv/"
      ".devenv.flake.nix"
      "devenv.local.nix"
      ".venv/"
      "node_modules/"
      "Zone.Identifier"
      "*:Zone.Identifier"
    ];
  };

  programs.gh = {
    enable = true;
    settings.git_protocol = "https";
    gitCredentialHelper.enable = true; # `gh auth login` becomes git's credential helper
  };

  programs.lazygit.enable = true;

  # --------------------------------------------------------------------------
  # Neovim — the binary comes from home.packages (above). On purpose I do not use
  # `programs.neovim`: it creates a read-only ~/.config/nvim/init.lua and that fights
  # LazyVim or your own config. So ~/.config/nvim stays entirely yours.
  #   - want LazyVim? run `lazyvim-init` (script below) once.
  # The fedora/sway branch had no Neovim config to bring over.
  # --------------------------------------------------------------------------
  # Optional LazyVim bootstrap (does not overwrite an existing config).
  home.file.".local/bin/lazyvim-init" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Install the LazyVim starter in ~/.config/nvim (needs gcc/make: bootstrap already installs them)
      set -euo pipefail
      cfg="''${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
      if [ -e "$cfg" ]; then
        echo "Already exists: $cfg — I will not overwrite it. Back it up or remove it, then run this again."
        exit 1
      fi
      git clone https://github.com/LazyVim/starter "$cfg"
      rm -rf "$cfg/.git"
      echo "LazyVim installed in $cfg. Open nvim and wait for the plugins to download."
    '';
  };

  # --------------------------------------------------------------------------
  # herdr: TUI plugins (gitview + nvim). herdr-chat stays out (macOS app).
  # plugins.json is the registry herdr 0.9.5 reads. The prefix+ keys below
  # do not collide with herdr's defaults (prefix+e is scrollback, prefix+o
  # opens the notification, prefix+v splits the pane, cmd+… does not exist on WSL).
  # ~/.config/nvim stays unmanaged.
  # --------------------------------------------------------------------------
  xdg.configFile."herdr/plugins.json".source = "${herdrPlugins.registry}/plugins.json";

  xdg.configFile."herdr/config.toml".text = ''
    # Plugin shortcuts. Everything else stays herdr's compiled default.
    [[keys.command]]
    key = "prefix+u"
    type = "plugin_action"
    command = "chmarax.gitview.toggle"
    description = "gitview in the current tab"

    [[keys.command]]
    key = "prefix+d"
    type = "plugin_action"
    command = "chmarax.gitview.toggle-tab"
    description = "gitview in its own tab"

    [[keys.command]]
    key = "prefix+a"
    type = "plugin_action"
    command = "chmarax.herdr-nvim.toggle"
    description = "nvim sidebar"

    [[keys.command]]
    key = "prefix+f"
    type = "plugin_action"
    command = "chmarax.herdr-nvim.pick-file"
    description = "open a file the agent touched"
  '';

  # Enter on a diff opens Nix's nvim, instead of falling through to xdg-open (no compositor).
  xdg.configFile."herdr/plugins/config/chmarax.gitview/config.toml".text = ''
    editor = ["${pkgs.neovim}/bin/nvim"]
  '';

  # The herdr-nvim binary looks up `nvim` on the server's PATH. Absolute path
  # of home-manager's Neovim, so the sidebar finds the editor even with a short PATH.
  xdg.configFile."herdr-nvim/config.toml".text = ''
    [sidebar]
    nvim_bin = "${pkgs.neovim}/bin/nvim"
  '';

  # home-manager itself (the `home-manager` command)
  programs.home-manager.enable = true;
}
