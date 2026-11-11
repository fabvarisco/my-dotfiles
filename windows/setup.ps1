<#
  setup.ps1 — prepara o Windows pro WSL (rode no PowerShell, de dentro da pasta do repo):

     powershell -ExecutionPolicy Bypass -File .\windows\setup.ps1

  O que faz:
    1. Atualiza o WSL (wsl --update)
    2. Copia windows\.wslconfig para %USERPROFILE%\.wslconfig (faz backup se já existir)
    3. Instala o Ubuntu 26.04 LTS (nome oficial: Ubuntu-26.04)
    4. (Opcional) instala o Zed for Windows via winget
  Se o WSL nunca foi instalado nesta máquina, o Windows pode pedir REINICIAR.
  Depois de reiniciar, rode este script de novo.
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

# Aplica a config nova antes de criar a distro (sparseVhd só vale p/ VHD novo)
wsl --shutdown

Write-Host "==> Distros instaladas:" -ForegroundColor Green
$installed = (wsl --list --quiet 2>$null) -replace "`0", "" | Where-Object { $_ -ne "" }
$installed | ForEach-Object { Write-Host "    $_" }

if ($installed -contains $Distro) {
  Write-Host "==> $Distro já está instalada — pulando." -ForegroundColor Green
} else {
  Write-Host "==> Instalando $Distro (vai pedir usuário e senha do Linux)" -ForegroundColor Green
  Write-Host "    Dica: use o MESMO usuário que está em user.nix (padrão: hitsu)."
  # Confira os nomes disponíveis com: wsl --list --online
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
