# ============================================================================
#  Ambiente Node por projeto.  Copie: devenv.nix + devenv.yaml + .envrc
#  Uso:  cd projeto && direnv allow     (ou: devenv shell)
#  Docs: https://devenv.sh/languages/javascript/   (opções: https://devenv.sh/reference/options/)
# ============================================================================
{ pkgs, ... }:

{
  # Ferramentas extras só deste projeto
  packages = [
    pkgs.git
  ];

  languages.javascript = {
    enable = true;
    package = pkgs.nodejs_24; # TROQUE a versão por projeto: nodejs_22, nodejs_24, nodejs_26...

    # Escolha UM gerenciador:
    npm.enable = true;
    # pnpm.enable = true;
    # bun.enable = true;

    # Roda `npm install` ao entrar no shell se package.json existir:
    # npm.install.enable = true;
  };

  # TypeScript LSP etc. ficam melhor no package.json do projeto (devDependencies).

  # Variáveis de ambiente do projeto
  env.NODE_ENV = "development";

  # Comandos nomeados:  `dev`  dentro do shell
  scripts.dev.exec = "npm run dev";

  # Processos de longa duração:  `devenv up`
  # processes.web.exec = "npm run dev";

  # Serviços (sem Docker!), ex.:
  # services.postgres.enable = true;
  # services.redis.enable = true;

  enterShell = ''
    echo "🟢 Node $(node --version) | npm $(npm --version)"
  '';

  # Git hooks (rodam no commit):
  # git-hooks.hooks.prettier.enable = true;
}
