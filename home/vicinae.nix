{ inputs, pkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
  mkExt = inputs.vicinae.lib.${system}.mkVicinaeExtension;
  extsSrc = inputs.vicinae-extensions;
  # Vicinae links with gcc15, but the Numen input is built with nixpkgs' default
  # stdenv (GCC 16). That pulls in GLIBCXX_3.4.36, which gcc15's libstdc++ lacks.
  numen = inputs.vicinae.inputs.numen.packages.${system}.numen.override {
    withRepl = false;
    stdenv = pkgs.gcc15Stdenv;
  };
  ext = name: mkExt {
    pname = name;
    version = "0-unstable-${extsSrc.shortRev or "unknown"}";
    src = "${extsSrc}/extensions/${name}";
  };
  localExt = name: mkExt {
    pname = name;
    version = "0-local";
    src = ../vicinae-extensions/${name};
  };
in
{
  imports = [ inputs.vicinae.homeManagerModules.default ];

  services.vicinae = {
    enable = true;
    package = inputs.vicinae.packages.${system}.default.override {
      inherit numen;
    };
    systemd = {
      enable = true;
      autoStart = true;
      environment = {
        USE_LAYER_SHELL = "1";
      };
    };
    settings = {
      close_on_focus_loss = false;
      pop_to_root_on_close = true;
      terminal = "kitty";
      font.normal = {
        size = 10;
        family = "JetBrains Mono Nerd Font";
      };
      launcher_window.opacity = 1.0;
      favorites = [
        "applications:cursor"
        "applications:zen-beta"
        "applications:org.gnome.Nautilus"
        "applications:vesktop"
      ];
    };
    extensions = [
      (localExt "noctalia-settings")
    ];
  };
}
