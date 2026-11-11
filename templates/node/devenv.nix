# ============================================================================
#  Per-project Node environment.  Copy: devenv.nix + devenv.yaml + .envrc
#  Use:  cd project && direnv allow     (or: devenv shell)
#  Docs: https://devenv.sh/languages/javascript/   (options: https://devenv.sh/reference/options/)
# ============================================================================
{ pkgs, ... }:

{
  # Extra tools for this project only
  packages = [
    pkgs.git
  ];

  languages.javascript = {
    enable = true;
    package = pkgs.nodejs_24; # CHANGE the version per project: nodejs_22, nodejs_24, nodejs_26...

    # Pick ONE package manager:
    npm.enable = true;
    # pnpm.enable = true;
    # bun.enable = true;

    # Run `npm install` when entering the shell if package.json exists:
    # npm.install.enable = true;
  };

  # TypeScript LSP and similar belong in the project's package.json (devDependencies).

  # Project environment variables
  env.NODE_ENV = "development";

  # Named commands:  `dev`  inside the shell
  scripts.dev.exec = "npm run dev";

  # Long-running processes:  `devenv up`
  # processes.web.exec = "npm run dev";

  # Services (no Docker!), for example:
  # services.postgres.enable = true;
  # services.redis.enable = true;

  enterShell = ''
    echo "🟢 Node $(node --version) | npm $(npm --version)"
  '';

  # Git hooks (they run on commit):
  # git-hooks.hooks.prettier.enable = true;
}
