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

Write-Host "==> Atualizando o WSL" -ForegroundColor Green
wsl --update

Write-Host "==> Copiando .wslconfig" -ForegroundColor Green
$src = Join-Path $PSScriptRoot ".wslconfig"
$dst = Join-Path $env:USERPROFILE ".wslconfig"
if (Test-Path $dst) {
  $bak = "$dst.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
  Copy-Item $dst $bak
  Write-Host "    backup do antigo: $bak"
}
Copy-Item $src $dst -Force
Write-Host "    -> $dst  (ajuste memory/processors pro seu PC!)" -ForegroundColor Yellow

# Apply the new config before creating the distro (sparseVhd only applies to a new VHD)
wsl --shutdown

Write-Host "==> Distros instaladas:" -ForegroundColor Green
$installed = (wsl --list --quiet 2>$null) -replace "`0", "" | Where-Object { $_ -ne "" }
$installed | ForEach-Object { Write-Host "    $_" }

if ($installed -contains $Distro) {
  Write-Host "==> $Distro já está instalada — pulando." -ForegroundColor Green
} else {
  Write-Host "==> Instalando $Distro (vai pedir usuário e senha do Linux)" -ForegroundColor Green
  Write-Host "    Dica: use o MESMO usuário que está em user.nix (padrão: hitsu)."
  # See the available names with: wsl --list --online
  wsl --install -d $Distro
}

if (-not $SkipZed) {
  if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "==> Instalando Zed for Windows (winget)" -ForegroundColor Green
    winget install -e --id ZedIndustries.Zed --accept-source-agreements --accept-package-agreements
  } else {
    Write-Host "winget não encontrado — baixe o Zed em https://zed.dev/download" -ForegroundColor Yellow
  }
}

Write-Host ""
Write-Host "Próximo passo, DENTRO do Ubuntu:" -ForegroundColor Cyan
Write-Host "  git clone -b wsl/ubuntu-nix https://github.com/fabvarisco/my-dotfiles"
Write-Host "  cd my-dotfiles && ./bootstrap.sh"
Write-Host "  (outra pasta tambem serve: o bootstrap usa o diretorio do proprio script)"
Write-Host ""
Write-Host "Backup da distro inteira (rode de vez em quando):" -ForegroundColor Cyan
Write-Host "  wsl --shutdown"
Write-Host "  wsl --export $Distro D:\backup\ubuntu-2604.tar"
Write-Host "Restaurar:"
Write-Host "  wsl --import $Distro C:\WSL\$Distro D:\backup\ubuntu-2604.tar"
