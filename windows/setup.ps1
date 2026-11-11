<#
  setup.ps1 — prepare Windows for WSL (run in PowerShell, from the repo folder):

     powershell -ExecutionPolicy Bypass -File .\windows\setup.ps1

  What it does:
    1. Updates WSL (wsl --update)
    2. Asks for WSL memory, CPUs, and swap (defaults: half of RAM, all cores, 4GB)
    3. Copies windows\.wslconfig to %USERPROFILE%\.wslconfig with those values
    4. Installs Ubuntu 26.04 LTS (official name: Ubuntu-26.04)
    5. (Optional) installs Zed for Windows via winget
  If WSL was never installed on this machine, Windows may ask you to REBOOT.
  After the reboot, run this script again.

  Non-interactive:
     powershell -ExecutionPolicy Bypass -File .\windows\setup.ps1 -Yes
     powershell -ExecutionPolicy Bypass -File .\windows\setup.ps1 -Memory 16GB -Processors 8 -Swap 4GB -Yes
#>
[CmdletBinding()]
param(
  [string]$Distro = "Ubuntu-26.04",
  [string]$Memory = "",
  [int]$Processors = 0,
  [string]$Swap = "",
  [switch]$SkipZed,
  [switch]$Yes
)
$ErrorActionPreference = "Stop"

function Get-DefaultMemoryGB {
  try {
    $bytes = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory
    $gb = [math]::Floor(($bytes / 1GB) / 2)
    if ($gb -lt 2) { return 2 }
    return [int]$gb
  } catch {
    return 4
  }
}

function Get-DefaultProcessors {
  try {
    $n = [Environment]::ProcessorCount
    if ($n -lt 1) { return 2 }
    return [int]$n
  } catch {
    return 2
  }
}

function Read-OrDefault([string]$Prompt, [string]$Default) {
  $ans = Read-Host "$Prompt [$Default]"
  if ([string]::IsNullOrWhiteSpace($ans)) { return $Default }
  return $ans.Trim()
}

$memDefault = "$(Get-DefaultMemoryGB)GB"
$cpuDefault = Get-DefaultProcessors
$swapDefault = "4GB"
$interactive = -not $Yes
if ($interactive) {
  try { $interactive = -not [Console]::IsInputRedirected } catch { $interactive = $true }
}

if ([string]::IsNullOrWhiteSpace($Memory)) {
  if ($interactive) { $Memory = Read-OrDefault "WSL memory" $memDefault } else { $Memory = $memDefault }
}
if ($Memory -match '^\d+$') { $Memory = "${Memory}GB" }

if ($Processors -lt 1) {
  if ($interactive) {
    $cpuText = Read-OrDefault "WSL processors" "$cpuDefault"
    $Processors = [int]$cpuText
  } else {
    $Processors = $cpuDefault
  }
}

if ([string]::IsNullOrWhiteSpace($Swap)) {
  if ($interactive) { $Swap = Read-OrDefault "WSL swap" $swapDefault } else { $Swap = $swapDefault }
}
if ($Swap -match '^\d+$') { $Swap = "${Swap}GB" }

Write-Host ""
Write-Host "WSL VM settings: memory=$Memory  processors=$Processors  swap=$Swap" -ForegroundColor Cyan
if ($interactive) {
  $ok = Read-Host "Write these into $env:USERPROFILE\.wslconfig? [Y/n]"
  if ($ok -match '^[Nn]') {
    Write-Host "Cancelled."
    exit 1
  }
}

Write-Host "==> Updating WSL" -ForegroundColor Green
wsl --update

Write-Host "==> Writing .wslconfig" -ForegroundColor Green
$src = Join-Path $PSScriptRoot ".wslconfig"
$dst = Join-Path $env:USERPROFILE ".wslconfig"
if (Test-Path $dst) {
  $bak = "$dst.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
  Copy-Item $dst $bak
  Write-Host "    backup of the old file: $bak"
}
$content = [System.IO.File]::ReadAllText($src)
$content = [regex]::Replace($content, '(?m)^memory=.*$', "memory=$Memory")
$content = [regex]::Replace($content, '(?m)^processors=.*$', "processors=$Processors")
$content = [regex]::Replace($content, '(?m)^swap=.*$', "swap=$Swap")
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($dst, $content.Replace("`n", "`r`n"), $utf8)
Write-Host "    -> $dst" -ForegroundColor Yellow

# Apply the new config before creating the distro (sparseVhd only applies to a new VHD)
wsl --shutdown

Write-Host "==> Installed distros:" -ForegroundColor Green
$installed = (wsl --list --quiet 2>$null) -replace "`0", "" | Where-Object { $_ -ne "" }
$installed | ForEach-Object { Write-Host "    $_" }

if ($installed -contains $Distro) {
  Write-Host "==> $Distro is already installed — skipping." -ForegroundColor Green
} else {
  Write-Host "==> Installing $Distro (it will ask for a Linux username and password)" -ForegroundColor Green
  Write-Host "    Tip: use the SAME username you give bootstrap.sh (default: your Windows name is not used; inside Ubuntu, bootstrap defaults to `$USER`)."
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
