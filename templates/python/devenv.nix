# ============================================================================
#  Ambiente Python por projeto (com uv).  Copie: devenv.nix + devenv.yaml + .envrc
#  Uso:  cd projeto && direnv allow     (ou: devenv shell)
#  Docs: https://devenv.sh/languages/python/   (opções: https://devenv.sh/reference/options/)
# ============================================================================
{ pkgs, ... }:

{
  packages = [
    pkgs.git
  ];

  languages.python = {
    enable = true;
    package = pkgs.python313; # TROQUE por projeto: python312, python313, python314...

    # .venv gerenciado + uv
    venv.enable = true;
    uv = {
      enable = true;
      # Roda `uv sync` ao entrar no shell (precisa de pyproject.toml):
      # sync.enable = true;
    };
  };

  env.PYTHONDONTWRITEBYTECODE = "1";

  # Comandos nomeados:  `tests`  dentro do shell (não use "test": é builtin do shell)
  scripts.tests.exec = "uv run pytest \"$@\"";

  # Serviços (sem Docker!), ex.:
  # services.postgres.enable = true;

  enterShell = ''
    echo "🐍 $(python --version) | uv $(uv --version | cut -d' ' -f2)"
  '';

  # git-hooks.hooks.ruff.enable = true;
}
