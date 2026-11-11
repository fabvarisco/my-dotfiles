# wsl/ubuntu-nix 🐧❄️

Ambiente de dev **reprodutível** no Windows: se o WSL quebrar, você apaga e recria
tudo igualzinho em ~15 minutos.

Branch de longa duração do repositório [my-dotfiles](https://github.com/fabvarisco/my-dotfiles), ao lado de `nixos/hyprland`, `fedora/sway` e `windows/glazewm-yasb`. Este branch **não é para merge** — ele vive sozinho, como os outros.

**Stack:** Ubuntu 26.04 LTS (WSL2) + Nix (instalador Determinate) + home-manager (flake) + devenv por projeto.

| O quê | Como vem |
|---|---|
| Shell | zsh + starship + autosuggestions + syntax highlighting + fzf + zoxide |
| CLI | ripgrep, fd, bat, eza, jq, curl, wget, unzip, zip, tree, htop, git, gh, lazygit |
| Editores | **Neovim** (Nix) · **Zed** (app do Windows conectado no WSL) |
| **herdr** | multiplexer de terminal para agentes de IA (nixpkgs) |
| IAs | `claude` (Claude Code), `codex` (OpenAI Codex CLI), `opencode` (todos do nixpkgs) |
| Linguagens globais | Node 26 (LTS), Python 3, uv (fallback; por projeto use devenv) |
| Por projeto | devenv + direnv + nix-direnv (`templates/node`, `templates/python`) |
| Sem | Docker, GPU/CUDA, compositor (Sway/Wayland) |

```
.
├── flake.nix          # entradas (nixpkgs-unstable + home-manager), travadas no flake.lock
├── flake.lock         # versões EXATAS de tudo (commite sempre!)
├── user.nix           # >>> EDITE: usuário, nome, e-mail <<<
├── home.nix           # pacotes, shell, git, aliases
├── starship.toml      # prompt vindo do fedora/sway (rótulo @wsl)
├── fastfetch/         # config, ASCII arts e random-logo.sh (também do fedora/sway)
├── bootstrap.sh       # roda dentro do Ubuntu novo; usa a própria pasta
├── windows/
│   ├── .wslconfig     # limites de RAM/CPU, rede mirrored, VHD sparse
│   └── setup.ps1      # instala WSL/Ubuntu-26.04, copia .wslconfig, instala Zed
└── templates/
    ├── node/          # devenv.nix + devenv.yaml + .envrc + .gitignore
    └── python/        # idem, com uv
```

## O que veio do `fedora/sway`

O prompt e o fastfetch deste branch são os do Fedora. O home-manager aplica cada um **uma vez** (sem `~/.bashrc.d` paralelo e sem um segundo `starship.toml`):

| Peça | Como entrou aqui |
|---|---|
| **Starship** | `starship.toml` (paleta `lock_dusk`, prompt numa linha) vira `programs.starship.settings`, com integração só no zsh. O rótulo do usuário passou de `@fedora` para `@wsl`. O formato `nix_shell` deste setup WSL continua, para aparecer dentro de `nix shell` / devenv. |
| **fastfetch** | `fastfetch/config.jsonc`, os três ASCII arts e o `random-logo.sh`. O pacote vem de `programs.fastfetch`; os arquivos, de `xdg.configFile` (o módulo não gera outro `config.jsonc`). No Fedora o script rodava no início do bash; aqui roda no fim do zsh interativo. A logo embutida sorteada junto com os ASCII arts passou de `fedora` para `ubuntu`. |

O branch Fedora **não tinha** aliases, `gitconfig` nem config de Neovim para trazer. Git (`programs.git`), aliases (`ls`/`ll`/`g`/`v`…) e o Neovim sem `init.lua` gerenciado já são deste setup WSL.

Ficou de fora tudo que é desktop/Wayland, porque o WSL desta branch não tem compositor: Sway, SwayFX, swaylock, Noctalia, Vicinae, Kitty, GTK, papéis de parede, `nwg-displays`, `pointer-accel` e a sessão em `system/`. Não havia waybar, wofi nem mako nesse branch (a barra do Fedora é a Noctalia).

---

## 0. Antes de tudo: edite `user.nix`

```nix
username = "hitsu";               # = usuário Linux que você vai criar no Ubuntu
fullName = "Fabricio Varisco";
email    = "fabricio.varisco@outlook.com";
```

(Se o `username` não bater com o seu usuário, o `bootstrap.sh` oferece corrigir sozinho.)

Suba este repo pro **seu GitHub** (privado tá ótimo). Ele é o seu backup de verdade.

---

## 1. Do Windows zerado até o terminal pronto

### 1.1 No Windows (PowerShell)

```powershell
# na pasta do repo (baixado/clonado no Windows)
powershell -ExecutionPolicy Bypass -File .\windows\setup.ps1
```

Ele faz: `wsl --update` → copia `windows\.wslconfig` para `%USERPROFILE%\.wslconfig`
(com backup do antigo) → `wsl --install -d Ubuntu-26.04` → `winget install ZedIndustries.Zed`.

> ⚠️ **Ajuste `memory` e `processors` no `.wslconfig`** pro seu PC (padrão do arquivo: 8GB / 8 núcleos).
> Se for a 1ª vez com WSL, o Windows pode pedir reinício; depois rode o script de novo.

Quer fazer na mão?

```powershell
wsl --install -d Ubuntu-26.04     # nomes disponíveis: wsl --list --online
copy windows\.wslconfig $env:USERPROFILE\.wslconfig
```

Na 1ª abertura do Ubuntu ele pede **usuário e senha** → use o mesmo `username` do `user.nix`.

### 1.2 Dentro do Ubuntu

```bash
git clone -b wsl/ubuntu-nix https://github.com/fabvarisco/my-dotfiles
cd my-dotfiles
./bootstrap.sh
```

A pasta pode ter outro nome (`git clone -b wsl/ubuntu-nix https://github.com/fabvarisco/my-dotfiles meu-wsl` e `cd meu-wsl`). O `bootstrap.sh` usa o diretório do próprio script — não procura `~/hitsu-wsl-setup`. Ele grava esse caminho em `~/.local/share/wsl-nix/flake-dir`, e os atalhos `hms` / `hmu` leem o arquivo.

Se o clone estiver em `/mnt/c/...` (disco do Windows), o script copia para `~/<nome-da-pasta>` e continua de lá. Projetos e este repo ficam no disco do Linux.

O `bootstrap.sh`:
1. `apt` só com o mínimo (curl, git, xz, zsh, build-essential, locales)
2. confere se o systemd está ligado (Ubuntu no WSL já vem com ele)
3. instala o Nix pelo instalador da Determinate Systems (flakes já ligados)
4. coloca seu usuário em `trusted-users` (pro cache binário do devenv funcionar)
5. `home-manager switch` → instala TUDO da tabela lá em cima
6. troca seu shell para zsh
7. mostra os próximos passos

Pode rodar de novo à vontade (é idempotente). `./bootstrap.sh --yes` não pergunta nada.

### 1.3 Logins (uma vez)

```bash
exec zsh -l             # ou feche e abra o terminal
gh auth login           # GitHub (também vira o credential helper do git)
claude                  # Claude Code — o login abre no navegador do Windows
codex login             # OpenAI Codex CLI
opencode auth login     # opencode
herdr                   # ctrl+b q desanexa; `herdr` de novo reanexa
```

> O navegador do Windows abre via `wsl-open` (`$BROWSER`). Se algum login não abrir
> sozinho, copie a URL que aparece no terminal e cole no navegador.

---

## 2. Zed: qual jeito usar? → **Zed do Windows + WSL remoto** ✅

O Zed para Windows abre pastas **dentro do WSL nativamente** (docs:
<https://zed.dev/docs/remote-development> → "WSL Support"). A UI roda no Windows (GPU, fontes,
atalhos nativos) e um servidor do Zed roda no Ubuntu — LSPs, terminal e git ficam no Linux.

- Abrir: `Ctrl+Shift+P` → **`projects: open wsl`** → escolha `Ubuntu-26.04` → pasta (ex.: `~/code/meu-app`).
- Pasta que já está no Windows: `projects: open folder in wsl`.
- Depois, fica em **Remote Projects** pra abrir com 1 clique.
- devenv/direnv: o Zed carrega o `.envrc` do projeto pros language servers (configuração `load_direnv`,
  padrão "direct"). Rode `direnv allow` uma vez no terminal antes.

**Por que não rodar o Zed Linux dentro do WSL (WSLg)?** Funciona, mas é renderizado por
WSLg (sem aceleração nativa, janela "estrangeira", clipboard/IME/HiDPI mais frágeis). Se mesmo
assim quiser: descomente `zed-editor` em `home.nix` e rode `hms`; o comando é `zeditor`.

---

## 3. Dia a dia

| Quero... | Comando |
|---|---|
| Aplicar mudança no `home.nix` / `user.nix` | `hms` |
| Atualizar **todos** os pacotes | `hmu` (= `nix flake update` + `home-manager switch`) |
| Adicionar um programa | coloque em `home.packages` no `home.nix` → `hms` → `git commit` |
| Procurar um pacote | `nix search nixpkgs <nome>` ou <https://search.nixos.org> |
| Testar algo sem instalar | `nix shell nixpkgs#cowsay -c cowsay oi` |
| LazyVim (opcional) | `lazyvim-init` (só se `~/.config/nvim` não existir) |
| Abrir pasta no Explorer | `explorer` |

Depois de `hmu`, **commite o `flake.lock`** — é ele que garante que outra máquina fique idêntica.

### Projeto novo com devenv

```bash
# na pasta do clone (my-dotfiles, ou o nome que você deu)
mkdir -p ~/code && cp -r templates/node ~/code/meu-app   # ou templates/python
cd ~/code/meu-app
direnv allow            # 1ª vez baixa as coisas; depois entra em <100 ms
```

- Troque a versão no `devenv.nix` (`pkgs.nodejs_22/24/26`, `pkgs.python312/313/314`).
- Serviços sem Docker: `services.postgres.enable = true;` → `devenv up`.
- Scripts: `dev` (node) / `tests` (python) já vêm de exemplo.
- Commite `devenv.nix`, `devenv.yaml`, `devenv.lock` e `.envrc`.
- Opções: <https://devenv.sh/reference/options/>

---

## 4. Rollback (deu ruim depois de atualizar)

```bash
home-manager generations                 # lista: data, id, caminho
/nix/store/<hash>-home-manager-generation/activate   # volta pra uma geração anterior
```

Ou pelo git (melhor): `git checkout <commit-bom> -- flake.lock home.nix && hms`.

Limpar gerações velhas e liberar disco:

```bash
home-manager expire-generations "-30 days"
nix-collect-garbage
```

---

## 5. Backup e restauração

**Backup de verdade = este repo no GitHub** (config) + seus projetos no GitHub.
Se o WSL morrer: `wsl --unregister Ubuntu-26.04`, reinstala, `./bootstrap.sh`. Pronto.

Backup da distro inteira (inclui arquivos soltos em `~`), no PowerShell:

```powershell
wsl --shutdown
wsl --export Ubuntu-26.04 D:\backup\ubuntu-2604.tar
# restaurar (em outra pasta/PC):
wsl --import Ubuntu-26.04 C:\WSL\Ubuntu-26.04 D:\backup\ubuntu-2604.tar
```

Depois de `--import` o WSL entra como **root**. Conserte com:

```bash
printf '[user]\ndefault=hitsu\n' | sudo tee -a /etc/wsl.conf    # troque hitsu
```

e `wsl --shutdown` no PowerShell.

---

## 6. Pegadinhas do WSL (leia!)

- **Projetos SEMPRE em `~/` (ex.: `~/code`), nunca em `/mnt/c/...`.** O disco do Windows via WSL é
  muito mais lento (npm install, git status, LSP) e quebra permissões/watchers.
  Acessar os arquivos do Linux pelo Explorer: `\\wsl$\Ubuntu-26.04\home\hitsu` (ou `explorer` no terminal).
- **Não instale Node/Python no Windows "pra usar no WSL".** Dentro do WSL o PATH do Windows entra
  no final; os do Nix vêm primeiro, mas evite confusão: `which node` deve apontar pra `~/.nix-profile`
  ou `/nix/store`.
- **CRLF:** o `.gitattributes` força LF (e CRLF no `windows/setup.ps1`, que também leva BOM UTF-8). Se clonar no Windows com `core.autocrlf=true`, o
  `bootstrap.sh` quebra (`/bin/bash^M`). Clone **dentro** do WSL.
- **Mudou o `.wslconfig`?** `wsl --shutdown` e espere ~8 s.
- **`sparseVhd`** só vale pra distro criada depois do `.wslconfig` — por isso o `setup.ps1` copia antes de instalar.
- **Rede mirrored:** `localhost:3000` do WSL abre direto no navegador do Windows (e vice-versa).
- **Arquivos novos no flake:** o Nix só enxerga arquivos rastreados pelo git → `git add` antes do `hms`.
- **Atualizações das IAs:** `claude`/`codex`/`opencode` vêm do Nix; o auto-update interno delas não
  funciona (o do Claude já vem desligado). Atualize com `hmu`. Se o nixpkgs atrasar e você precisar
  de uma versão do dia, use os instaladores oficiais temporariamente:
  - Claude Code: `curl -fsSL https://claude.ai/install.sh | bash` · <https://code.claude.com/docs/en/setup>
  - Codex: `curl -fsSL https://chatgpt.com/codex/install.sh | sh` · <https://github.com/openai/codex>
  - opencode: `curl -fsSL https://opencode.ai/v2/install | bash` · <https://opencode.ai>
  - herdr: `curl -fsSL https://herdr.dev/install.sh | sh` · <https://github.com/herdrdev/herdr>
  (o `~/.local/bin` fica DEPOIS do Nix no PATH; pra usar a versão manual, tire o pacote do `home.nix` e rode `hms`. Confira com `which -a claude`.)
- **NixOS-WSL?** Dá pra ter como 2ª distro pra brincar, mas binários prontos (npm/pip com
  binários, SDKs) precisam de `nix-ld`. Por isso a base aqui é Ubuntu.

---

## 7. Desinstalar o Nix (se um dia quiser)

```bash
/nix/nix-installer uninstall
```
