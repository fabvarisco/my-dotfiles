Name:           sway-config-nix
Version:        1
Release:        2
Summary:        Sway login session for a Home Manager configuration
License:        MIT
BuildArch:      noarch

# The sway package requires this virtual provide. This package replaces
# sway-config-fedora so Waybar is no longer pulled in.
Provides:       sway-config = 1.8+%{version}-%{release}
Obsoletes:      sway-config-fedora < 1
Conflicts:      waybar

Source0:        start-sway
Source1:        sway.desktop
Source2:        LICENSE

%description
Session entry for Sway. The compositor configuration is managed by Home Manager.

%prep

%build

%install
install -Dm755 %{SOURCE0} %{buildroot}%{_bindir}/start-sway
install -Dm644 %{SOURCE1} %{buildroot}%{_datadir}/wayland-sessions/sway.desktop
install -Dm644 %{SOURCE2} %{buildroot}%{_datadir}/licenses/%{name}/LICENSE

%files
%{_bindir}/start-sway
%{_datadir}/wayland-sessions/sway.desktop
%{_datadir}/licenses/%{name}/LICENSE
