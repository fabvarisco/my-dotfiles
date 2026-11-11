# ============================================================================
#  home.nix — tudo que é "seu" no WSL: pacotes, shell, git, editores, IAs.
#  Depois de editar:  hms
#  (atalho de `home-manager switch --flake <pasta do clone>`).
#  A pasta NÃO é fixa: o bootstrap.sh grava o caminho em
#  ~/.local/share/wsl-nix/flake-dir e o zsh lê esse arquivo.
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

  # Versão do formato de estado do home-manager. NÃO mude depois do 1º switch
  # (não tem nada a ver com a versão dos pacotes).
  home.stateVersion = "26.05";

  # Ubuntu não é NixOS: isso ajusta XDG_DATA_DIRS, locale etc.
  targets.genericLinux.enable = true;
  # Sem GPU no WSL (não precisamos de drivers OpenGL/CUDA pros pacotes Nix).
  targets.genericLinux.gpu.enable = false;

  # --------------------------------------------------------------------------
  # Pacotes
  # --------------------------------------------------------------------------
  home.packages = (with pkgs; [
    # --- CLI do dia a dia ---
    ripgrep
    fd
    jq
    curl
    wget
    unzip
    zip
    tree
    htop
    wsl-open # abre links/arquivos no navegador/app padrão do Windows (login das IAs)

    # --- Multiplexer dos agentes (OBRIGATÓRIO) ---
    # herdr: "the runtime your coding agents live on" — https://github.com/herdrdev/herdr
    # Empacotado no nixpkgs (pkgs/by-name/he/herdr).
    herdr

    # --- IAs de código (todas do nixpkgs-unstable) ---
    claude-code # comando: claude   (unfree -> allowUnfree no flake.nix)
    codex # comando: codex    (OpenAI Codex CLI)
    opencode # comando: opencode

    # --- Linguagens globais (fallback; por projeto use devenv) ---
    nodejs_26 # Node 26 = LTS ativa ("Lithium") desde out/2026
    python3
    uv # gerenciador Python rápido (venv, pip, python versions)

    # --- Editores ---
    neovim # nvim / vi / vim (aliases abaixo)

    # --- Ambientes por projeto ---
    devenv

    # --- Nix: formatter + LSP (útil no Zed/Neovim pra editar este repo) ---
    nixfmt
    nil

    # --- Zed DENTRO do WSL (via WSLg) — desligado de propósito.
    # Recomendado: Zed nativo do Windows + "Open WSL" (ver README).
    # Descomente se quiser rodar o Zed Linux por WSLg:
    # zed-editor

    # fastfetch entra por programs.fastfetch (não duplicar aqui).
    # starship entra por programs.starship.
  ]) ++ [
    # Binários dos plugins (o herdr em si chama a cópia dentro do plugin root).
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
    BROWSER = "wsl-open"; # claude/codex/opencode/gh abrem o login no navegador do Windows
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  # --------------------------------------------------------------------------
  # Shell: zsh + starship + fastfetch
  # Starship e fastfetch vieram do branch fedora/sway.
  # Starship é gerenciado SÓ por programs.starship (não há xdg.configFile
  # nem eval manual no zsh — isso duplicaria o prompt).
  # fastfetch: o pacote vem do módulo; os arquivos (config, ASCII, script)
  # vêm de xdg.configFile. programs.fastfetch.settings fica vazio de
  # propósito, senão o módulo também gera config.jsonc e briga com a pasta.
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

    # Garante o Nix no PATH mesmo se /etc/zsh/zshenv não carregar o profile.
    # HM_FLAKE_DIR segue a pasta em que o bootstrap.sh rodou.
    envExtra = ''
      if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ] && [ -z "$__ETC_PROFILE_NIX_SOURCED" ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi
      if [ -f "$HOME/.local/share/wsl-nix/flake-dir" ]; then
        IFS= read -r HM_FLAKE_DIR < "$HOME/.local/share/wsl-nix/flake-dir"
        export HM_FLAKE_DIR
      fi
    '';

    # hms/hmu são funções (a pasta do flake não é fixa). O fastfetch roda
    # no fim do zshrc, como o bash do Fedora rodava random-logo.sh.
    initContent = lib.mkMerge [
      (lib.mkOrder 1000 ''
        hm-flake-dir() {
          local dir="''${HM_FLAKE_DIR:-}"
          if [[ -z $dir && -f $HOME/.local/share/wsl-nix/flake-dir ]]; then
            IFS= read -r dir < "$HOME/.local/share/wsl-nix/flake-dir"
          fi
          if [[ -z $dir || ! -d $dir ]]; then
            echo "Não achei o flake. Rode ./bootstrap.sh na pasta do clone (ele grava ~/.local/share/wsl-nix/flake-dir)." >&2
            return 1
          fi
          printf '%s\n' "$dir"
        }
        hms() {
          local dir
          dir="$(hm-flake-dir)" || return
          home-manager switch --flake "$dir"
        }
        hmu() {
          local dir
          dir="$(hm-flake-dir)" || return
          nix flake update --flake "$dir" && home-manager switch --flake "$dir"
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
      # `lg` fica com a função do programs.lazygit (cd ao sair). Um alias
      # com o mesmo nome esconderia essa função.
      v = "nvim";
      vi = "nvim";
      vim = "nvim";
      # Abrir a pasta atual no Explorer do Windows
      explorer = "explorer.exe .";
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    # settings do starship.toml (fedora/sway), mais o nix_shell deste setup.
    settings = lib.recursiveUpdate (builtins.fromTOML (builtins.readFile ./starship.toml)) {
      nix_shell.format = "via [❄️ $state( \\($name\\))]($style) ";
    };
  };

  programs.fastfetch.enable = true;

  xdg.configFile."fastfetch" = {
    source = ./fastfetch;
    recursive = true;
  };

  # direnv + nix-direnv: entra na pasta do projeto -> devenv carrega sozinho
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
    enable = true; # `z pasta` pula pra pastas usadas recentemente
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
      core.autocrlf = "input"; # evita o inferno de CRLF vindo do Windows
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
    gitCredentialHelper.enable = true; # `gh auth login` vira o credential helper do git
  };

  programs.lazygit.enable = true;

  # --------------------------------------------------------------------------
  # Neovim — o binário vem de home.packages (lá em cima). De propósito NÃO uso
  # `programs.neovim`: ele cria ~/.config/nvim/init.lua read-only e isso briga
  # com LazyVim/config própria. Assim ~/.config/nvim continua 100% seu.
  #   - quer LazyVim? rode `lazyvim-init` (script abaixo) uma vez.
  # O branch fedora/sway não tinha config de Neovim para trazer.
  # --------------------------------------------------------------------------
  # Bootstrap opcional do LazyVim (não sobrescreve config existente).
  home.file.".local/bin/lazyvim-init" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Instala o LazyVim starter em ~/.config/nvim (precisa de gcc/make: o bootstrap já instala)
      set -euo pipefail
      cfg="''${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
      if [ -e "$cfg" ]; then
        echo "Já existe $cfg — não vou sobrescrever. Faça backup/remova e rode de novo."
        exit 1
      fi
      git clone https://github.com/LazyVim/starter "$cfg"
      rm -rf "$cfg/.git"
      echo "LazyVim instalado em $cfg. Abra o nvim e espere os plugins baixarem."
    '';
  };

  # --------------------------------------------------------------------------
  # herdr: plugins TUI (gitview + nvim). herdr-chat fica de fora (app macOS).
  # plugins.json é o registro que o herdr 0.9.5 lê. As chaves prefix+ abaixo
  # não batem com os defaults do herdr (prefix+e é o scrollback, prefix+o
  # abre a notificação, prefix+v divide o pane, cmd+… não existe no WSL).
  # ~/.config/nvim continua sem ser gerenciado.
  # --------------------------------------------------------------------------
  xdg.configFile."herdr/plugins.json".source = "${herdrPlugins.registry}/plugins.json";

  xdg.configFile."herdr/config.toml".text = ''
    # Atalhos dos plugins. O resto fica no default compilado do herdr.
    [[keys.command]]
    key = "prefix+u"
    type = "plugin_action"
    command = "chmarax.gitview.toggle"
    description = "gitview na aba atual"

    [[keys.command]]
    key = "prefix+d"
    type = "plugin_action"
    command = "chmarax.gitview.toggle-tab"
    description = "gitview numa aba"

    [[keys.command]]
    key = "prefix+a"
    type = "plugin_action"
    command = "chmarax.herdr-nvim.toggle"
    description = "sidebar do nvim"

    [[keys.command]]
    key = "prefix+f"
    type = "plugin_action"
    command = "chmarax.herdr-nvim.pick-file"
    description = "abrir arquivo que o agente tocou"
  '';

  # Enter no diff abre o nvim do Nix, sem cair no xdg-open (não há compositor).
  xdg.configFile."herdr/plugins/config/chmarax.gitview/config.toml".text = ''
    editor = ["${pkgs.neovim}/bin/nvim"]
  '';

  # O binário do herdr-nvim procura `nvim` no PATH do servidor. Caminho absoluto
  # do Neovim do home-manager, para a sidebar achar o editor mesmo com PATH curto.
  xdg.configFile."herdr-nvim/config.toml".text = ''
    [sidebar]
    nvim_bin = "${pkgs.neovim}/bin/nvim"
  '';

  # O próprio home-manager (comando `home-manager`)
  programs.home-manager.enable = true;
}
