# ============================================================================
#  Per-project Python environment (with uv).  Copy: devenv.nix + devenv.yaml + .envrc
#  Use:  cd project && direnv allow     (or: devenv shell)
#  Docs: https://devenv.sh/languages/python/   (options: https://devenv.sh/reference/options/)
# ============================================================================
{ pkgs, ... }:

{
  packages = [
    pkgs.git
  ];

  languages.python = {
    enable = true;
    package = pkgs.python313; # CHANGE per project: python312, python313, python314...

    # managed .venv + uv
    venv.enable = true;
    uv = {
      enable = true;
      # Run `uv sync` when entering the shell (needs pyproject.toml):
      # sync.enable = true;
    };
  };

  env.PYTHONDONTWRITEBYTECODE = "1";

  # Named commands:  `tests`  inside the shell (do not use "test": it is a shell builtin)
  scripts.tests.exec = "uv run pytest \"$@\"";

  # Services (no Docker!), for example:
  # services.postgres.enable = true;

  enterShell = ''
    echo "🐍 $(python --version) | uv $(uv --version | cut -d' ' -f2)"
  '';

  # git-hooks.hooks.ruff.enable = true;
}
