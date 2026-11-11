# Template for per-person answers. bootstrap.sh writes the real file to
# ~/.config/wsl-nix/user.nix and to ./user.nix, then marks ./user.nix
# skip-worktree so these placeholders stay what git commits.
# Nix only reads tracked files, so ./user.nix cannot be gitignored.
{
  username = "user";
  fullName = "Your Name";
  email = "you@example.com";
  system = "x86_64-linux"; # or aarch64-linux
  editor = "nvim"; # nvim, zed, or other
  editorCommand = "nvim"; # used when editor = "other"
  gitDefaultBranch = "main";
  aiClis = [
    "claude-code"
    "codex"
    "opencode"
  ];
  herdr = true;
  fastfetchOnStart = true;
  zshAsLoginShell = true;
}
