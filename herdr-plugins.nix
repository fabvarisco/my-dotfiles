# Plugins do herdr TUI (0.9.5) que rodam no WSL sem compositor.
# nixpkgs não tem herdr-gitview nem herdr-nvim. O fonte é o tag de release
# (rev pinado) e o binário é o asset Linux que o herdr/install.sh baixa.
# herdr-chat não entra aqui: é mod do app desktop, só macOS.
{ pkgs }:

let
  # ChmaraX/herdr-gitview tag v0.5.0
  gitviewRev = "00f0f64b32447a0b6a8073b8b551f45d983f2b3b";
  # ChmaraX/herdr-nvim tag v1.3.1
  nvimRev = "88a68c77fe82476bdfcba39d36c3fa37109f35a8";

  gitviewSrc = pkgs.fetchFromGitHub {
    owner = "ChmaraX";
    repo = "herdr-gitview";
    rev = gitviewRev;
    hash = "sha256-3EBZ1d0AOdm07RK4dPXfMjLcqAeZVcBcrjvStS0QxjI=";
  };

  nvimSrc = pkgs.fetchFromGitHub {
    owner = "ChmaraX";
    repo = "herdr-nvim";
    rev = nvimRev;
    hash = "sha256-/026mNSbhZIAMJeNdSsbi9vhUuQEfdjqI99QzKAHW6w=";
  };

  gitviewBin = pkgs.fetchurl {
    url = "https://github.com/ChmaraX/herdr-gitview/releases/download/v0.5.0/herdr-gitview-v0.5.0-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-gYBKtP6BP9arKz6JN6ZlBYduoxKn1EhRoRSUtL96jyY=";
  };

  nvimBin = pkgs.fetchurl {
    url = "https://github.com/ChmaraX/herdr-nvim/releases/download/v1.3.1/herdr-nvim-x86_64-unknown-linux-gnu";
    hash = "sha256-41tbpzmJzyAmLaz8i/tOytBgSJ2eO+o77v9fWELY1xg=";
  };

  # Raiz que o `herdr plugin link` registra. O binário oficial fica em bin/.
  herdr-gitview = pkgs.stdenv.mkDerivation {
    pname = "herdr-gitview-plugin";
    version = "0.5.0";
    src = gitviewSrc;
    nativeBuildInputs = [ pkgs.gnutar ];
    dontBuild = true;
    installPhase = ''
      mkdir -p "$out"
      cp -a . "$out/"
      chmod -R u+w "$out"
      mkdir -p "$out/bin"
      tar -xzf ${gitviewBin} -C "$out/bin"
      chmod 755 "$out/bin/herdr-gitview"
      # O run.sh upstream só acrescenta Homebrew/cargo. O git e o nvim
      # deste setup estão em ~/.nix-profile/bin.
      substituteInPlace "$out/herdr/run.sh" \
        --replace-fail \
        'PATH="$PATH:/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$HOME/.cargo/bin"' \
        'PATH="$PATH:/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.nix-profile/bin"'
    '';
  };

  herdr-nvim = pkgs.stdenv.mkDerivation {
    pname = "herdr-nvim-plugin";
    version = "1.3.1";
    src = nvimSrc;
    dontBuild = true;
    installPhase = ''
      mkdir -p "$out/bin"
      cp -a . "$out/"
      chmod -R u+w "$out"
      install -m 755 ${nvimBin} "$out/bin/herdr-nvim.bin"
      # O manifesto chama bin/herdr-nvim. O binário não põe o perfil Nix
      # no PATH (só Homebrew e ~/.local); o wrapper acrescenta.
      cat > "$out/bin/herdr-nvim" << 'EOF'
      #!/bin/sh
      dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
      export PATH="$HOME/.nix-profile/bin:$PATH"
      exec "$dir/herdr-nvim.bin" "$@"
      EOF
      chmod 755 "$out/bin/herdr-nvim"
    '';
  };

  # plugins.json no formato que o herdr 0.9.5 grava em `plugin link`.
  registry = pkgs.runCommand "herdr-plugins-json" { nativeBuildInputs = [ pkgs.herdr ]; } ''
    export HOME=$TMPDIR/home
    export XDG_CONFIG_HOME=$TMPDIR/config
    export XDG_STATE_HOME=$TMPDIR/state
    mkdir -p "$HOME"
    herdr plugin link ${herdr-gitview}
    herdr plugin link ${herdr-nvim}
    mkdir -p "$out"
    cp "$XDG_CONFIG_HOME/herdr/plugins.json" "$out/plugins.json"
  '';
in
{
  inherit
    herdr-gitview
    herdr-nvim
    registry
    gitviewRev
    nvimRev
    ;
}
