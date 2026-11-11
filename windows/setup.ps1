<#
  setup.ps1 — prepare Windows for WSL (run in PowerShell, from the repo folder):

     powershell -ExecutionPolicy Bypass -File .\windows\setup.ps1

  What it does:
    1. Updates WSL (wsl --update)
    2. Copies windows\.wslconfig to %USERPROFILE%\.wslconfig (backs up the old file if it exists)
    3. Installs Ubuntu 26.04 LTS (official name: Ubuntu-26.04)
    4. (Optional) installs Zed for Windows via winget
  If WSL was never installed on this machine, Windows may ask you to REBOOT.
  After the reboot, run this script again.
#>
[CmdletBinding()]
param(
  [string]$Distro = "Ubuntu-26.04",
  [switch]$SkipZed
)
$ErrorActionPreference = "Stop"

Write-Host "==> Updating WSL" -ForegroundColor Green
wsl --update

Write-Host "==> Copying .wslconfig" -ForegroundColor Green
$src = Join-Path $PSScriptRoot ".wslconfig"
$dst = Join-Path $env:USERPROFILE ".wslconfig"
if (Test-Path $dst) {
  $bak = "$dst.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
  Copy-Item $dst $bak
  Write-Host "    backup of the old file: $bak"
}
Copy-Item $src $dst -Force
Write-Host "    -> $dst  (adjust memory/processors for your PC!)" -ForegroundColor Yellow

# Apply the new config before creating the distro (sparseVhd only applies to a new VHD)
wsl --shutdown

Write-Host "==> Installed distros:" -ForegroundColor Green
$installed = (wsl --list --quiet 2>$null) -replace "`0", "" | Where-Object { $_ -ne "" }
$installed | ForEach-Object { Write-Host "    $_" }

if ($installed -contains $Distro) {
  Write-Host "==> $Distro is already installed — skipping." -ForegroundColor Green
} else {
  Write-Host "==> Installing $Distro (it will ask for a Linux username and password)" -ForegroundColor Green
  Write-Host "    Tip: use the SAME username as user.nix (default: hitsu)."
  # See the available names with: wsl --list --online
  wsl --install -d $Distro
}

if (-not $SkipZed) {
  if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "==> Installing Zed for Windows (winget)" -ForegroundColor Green
    winget install -e --id ZedIndustries.Zed --accept-source-agreements --accept-package-agreements
  } else {
    Write-Host "winget was not found — download Zed from https://zed.dev/download" -ForegroundColor Yellow
  }
}

Write-Host ""
Write-Host "Next step, INSIDE Ubuntu:" -ForegroundColor Cyan
Write-Host "  git clone -b wsl/ubuntu-nix https://github.com/fabvarisco/my-dotfiles"
Write-Host "  cd my-dotfiles && ./bootstrap.sh"
Write-Host "  (another folder name is fine: bootstrap uses the script's own directory)"
Write-Host ""
Write-Host "Full distro backup (run this from time to time):" -ForegroundColor Cyan
Write-Host "  wsl --shutdown"
Write-Host "  wsl --export $Distro D:\backup\ubuntu-2604.tar"
Write-Host "Restore:"
Write-Host "  wsl --import $Distro C:\WSL\$Distro D:\backup\ubuntu-2604.tar"
