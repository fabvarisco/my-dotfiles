#!/usr/bin/env bash
# ============================================================================
#  bootstrap.sh — monta o ambiente dev num Ubuntu WSL novinho.
#  Rode DENTRO do WSL, como seu usuário normal (não root). A pasta do clone
#  pode ter qualquer nome; o script usa o próprio diretório:
#
#     git clone -b wsl/ubuntu-nix https://github.com/fabvarisco/my-dotfiles
#     cd my-dotfiles && ./bootstrap.sh
#
#  Pode rodar de novo quantas vezes quiser (idempotente).
#  Flags:  -y / --yes   não pergunta nada (aceita os padrões)
# ============================================================================
set -euo pipefail

ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    -y | --yes) ASSUME_YES=1 ;;
    -h | --help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *)
      echo "flag desconhecida: $arg" >&2
      exit 2
      ;;
  esac
done

c_green=$'\033[32m'; c_yellow=$'\033[33m'; c_red=$'\033[31m'; c_reset=$'\033[0m'
step() { printf '\n%s==>%s %s\n' "$c_green" "$c_reset" "$*"; }
warn() { printf '%s[!]%s %s\n' "$c_yellow" "$c_reset" "$*"; }
die() { printf '%s[x]%s %s\n' "$c_red" "$c_reset" "$*" >&2; exit 1; }
confirm() { # confirm "pergunta" -> 0 = sim (padrão sim)
  [ "$ASSUME_YES" = 1 ] && return 0
  local ans
  read -r -p "$1 [S/n] " ans || true
  [[ -z "$ans" || "$ans" =~ ^[SsYy] ]]
}

# ----------------------------------------------------------------------------
# 0. Sanidade
# ----------------------------------------------------------------------------
[ "$(id -u)" -ne 0 ] || die "Não rode como root. Rode como seu usuário (o sudo é chamado quando precisar)."
if ! grep -qi microsoft /proc/version 2>/dev/null; then
  warn "Isso não parece ser WSL. Vou continuar mesmo assim."
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Repo dentro de /mnt/c é LENTO e dá problema de permissão -> copia pra ~/
# com o mesmo nome da pasta (não assume hitsu-wsl-setup nem my-dotfiles).
case "$SCRIPT_DIR" in
  /mnt/*)
    repo_name="$(basename "$SCRIPT_DIR")"
    dest="$HOME/$repo_name"
    step "O repo está em $SCRIPT_DIR (disco do Windows). Copiando pra $dest"
    if [ -e "$dest" ]; then
      die "$dest já existe. Rode o bootstrap de lá: cd \"$dest\" && ./bootstrap.sh"
    fi
    cp -a "$SCRIPT_DIR" "$dest"
    exec "$dest/bootstrap.sh" "$@"
    ;;
esac

cd "$SCRIPT_DIR"

mkdir -p "$HOME/.local/share/wsl-nix"
printf '%s\n' "$SCRIPT_DIR" > "$HOME/.local/share/wsl-nix/flake-dir"

# ----------------------------------------------------------------------------
# 1. Pacotes mínimos do apt (o resto vem do Nix)
# ----------------------------------------------------------------------------
step "Instalando dependências mínimas via apt"
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ca-certificates curl git xz-utils zsh build-essential locales

# Locale UTF-8 (evita caracteres quebrados no starship/herdr)
if ! locale -a 2>/dev/null | grep -qi '^en_US\.utf-\?8$'; then
  sudo locale-gen en_US.UTF-8
fi

# ----------------------------------------------------------------------------
# 2. systemd (o daemon do Nix depende dele). Ubuntu no WSL já vem com ele ligado.
# ----------------------------------------------------------------------------
if [ "$(ps -p 1 -o comm= 2>/dev/null)" != "systemd" ]; then
  warn "systemd não está rodando como PID 1."
  if ! grep -qs '^systemd *= *true' /etc/wsl.conf; then
    step "Ativando systemd em /etc/wsl.conf"
    printf '\n[boot]\nsystemd=true\n' | sudo tee -a /etc/wsl.conf >/dev/null
  fi
  die "Feche o WSL, rode no PowerShell:  wsl --shutdown   e depois rode este script de novo."
fi

# ----------------------------------------------------------------------------
# 3. Nix (instalador da Determinate Systems: flakes ligados, desinstalação limpa)
# ----------------------------------------------------------------------------
if [ -e /nix/var/nix/profiles/default/bin/nix ]; then
  step "Nix já instalado — pulando"
else
  step "Instalando Nix (Determinate Systems)"
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
fi

# Carrega o Nix nesta sessão
# shellcheck disable=SC1091
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# Seu usuário como trusted-user -> o devenv consegue usar o cache binário dele
# (sem isso, muita coisa compila do zero). Determinate usa nix.custom.conf.
NIX_CUSTOM=/etc/nix/nix.custom.conf
if ! sudo grep -qs "^trusted-users.*\b$USER\b" "$NIX_CUSTOM"; then
  step "Adicionando $USER em trusted-users ($NIX_CUSTOM)"
  echo "trusted-users = root $USER" | sudo tee -a "$NIX_CUSTOM" >/dev/null
  sudo systemctl restart nix-daemon.service 2>/dev/null || true
fi

nix --version

# ----------------------------------------------------------------------------
# 4. Confere o usuário em user.nix
# ----------------------------------------------------------------------------
FLAKE_USER="$(sed -n 's/^[[:space:]]*username[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' user.nix | head -n1)"
if [ "$FLAKE_USER" != "$USER" ]; then
  warn "user.nix tem username = \"$FLAKE_USER\", mas seu usuário é \"$USER\"."
  if confirm "Trocar automaticamente para \"$USER\" no user.nix?"; then
    sed -i "s/^\([[:space:]]*username[[:space:]]*=[[:space:]]*\)\"[^\"]*\"/\1\"$USER\"/" user.nix
  else
    die "Edite user.nix e rode de novo."
  fi
fi
if grep -q 'seu-email@exemplo.com' user.nix; then
  warn "user.nix ainda tem o e-mail de exemplo. Edite depois e rode: hms"
fi

# Flakes só enxergam arquivos rastreados pelo git
if [ ! -d .git ]; then
  git init -q -b main
fi
git add -A

# ----------------------------------------------------------------------------
# 5. home-manager switch (instala TUDO: zsh, nvim, herdr, IAs, node, python...)
# ----------------------------------------------------------------------------
step "Aplicando a configuração do home-manager (a 1ª vez demora)"
nix run .#home-manager -- switch --flake ".#$USER" -b hm-backup

# ----------------------------------------------------------------------------
# 6. zsh como shell padrão (usa o zsh do apt: /usr/bin/zsh; a config vem do home-manager)
# ----------------------------------------------------------------------------
ZSH_BIN="$(command -v zsh || true)"
[ -x /usr/bin/zsh ] && ZSH_BIN=/usr/bin/zsh
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
if [ -n "$ZSH_BIN" ] && [ "$CURRENT_SHELL" != "$ZSH_BIN" ]; then
  step "Trocando seu shell padrão para $ZSH_BIN"
  grep -qx "$ZSH_BIN" /etc/shells || echo "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null
  sudo chsh -s "$ZSH_BIN" "$USER"
fi

# ----------------------------------------------------------------------------
# 7. Instalações fora do Nix: NENHUMA necessária.
#    herdr, claude-code, codex, opencode, devenv, node, python, uv -> nixpkgs.
#    (Se algum dia um sair do nixpkgs, os instaladores oficiais estão no README.)
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# 8. Próximos passos
# ----------------------------------------------------------------------------
cat <<MSG

${c_green}✔ Pronto!${c_reset}  Feche e abra o terminal (ou rode: exec zsh -l)

Próximos passos:
  1. Confira ${SCRIPT_DIR}/user.nix (usuário/nome/e-mail do git) e rode:  hms
  2. GitHub:        gh auth login
  3. Claude Code:   claude          (login abre no navegador do Windows)
  4. Codex:         codex login
  5. opencode:      opencode auth login
  6. herdr:         herdr           (ctrl+b q desanexa, 'herdr' reanexa)
  7. Novo projeto:  cp -r ${SCRIPT_DIR}/templates/node ~/code/meu-app   (inclui .envrc)
                    cd ~/code/meu-app && direnv allow
  8. Zed (Windows): Ctrl+Shift+P -> "projects: open wsl" -> escolha Ubuntu-26.04

Atualizar tudo:  hmu        Voltar versão:  home-manager generations  (ver README)
MSG
