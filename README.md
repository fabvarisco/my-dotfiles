# NixOS Hyprland (Beelink)

Flake for this machine: Hyprland, Noctalia, Vicinae, and SilentSDDM. The only configuration is `beelink-hypr`, user `fabvarisco`.

[hosts/beelink/hardware-configuration.nix](hosts/beelink/hardware-configuration.nix) points at the disks of this install. On another disk, generate a new one and replace that file before installing.

## Clean install

From the NixOS installer (UEFI, `x86_64`):

```bash
sudo parted /dev/nvme0n1 -- mklabel gpt
sudo parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
sudo parted /dev/nvme0n1 -- set 1 esp on
sudo parted /dev/nvme0n1 -- mkpart primary ext4 512MiB 100%

sudo mkfs.fat -F 32 -n boot /dev/nvme0n1p1
sudo mkfs.ext4 -L nixos /dev/nvme0n1p2

sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/boot /mnt/boot
```

Use a different device than `nvme0n1` if that is not the disk. Check with `lsblk`.

Generate the hardware config and put the flake in place of the generated configuration:

```bash
sudo nixos-generate-config --root /mnt

sudo nix-shell -p git --run 'git clone --branch nixos/hyprland https://github.com/fabvarisco/my-dotfiles /mnt/etc/nixos/my-dotfiles'

sudo cp /mnt/etc/nixos/hardware-configuration.nix \
  /mnt/etc/nixos/my-dotfiles/hosts/beelink/hardware-configuration.nix
```

Install and set the user password. The flake does not ship one:

```bash
cd /mnt/etc/nixos/my-dotfiles
sudo nixos-install --flake .#beelink-hypr
sudo nixos-enter --root /mnt -c 'passwd fabvarisco'
sudo reboot
```

On the first evaluation, Nix asks whether to trust the flake substituters (`hyprland`, `nix-community`, `zen-browser`). Accept them. The Zen cache is used only when the user is in `nix.settings.trusted-users`; otherwise the rebuild continues and ignores that cache.

The graphical login is SilentSDDM. Pick the Hyprland session.

## Already installed

```bash
cd ~/Developer/my-dotfiles
git pull
sudo nixos-rebuild switch --flake .#beelink-hypr
```

## Shortcuts

| Shortcut | Action |
| --- | --- |
| Super+Return | Kitty |
| Alt+Space | Vicinae |
| Super+V | Clipboard history |
| Super+E | Files |
| Super+Q | Close window |
| Super+D | hyprmon |
| Super+L | Lock |
