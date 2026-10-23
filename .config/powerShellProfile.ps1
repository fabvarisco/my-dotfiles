# Minimal profile: UTF‑8 + Oh My Posh (if installed) + Fastfetch with explicit config path
try {
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    chcp 65001 > $null
} catch {}

Clear-Host

# Force Fastfetch to use YOUR config every time (bypass path confusion)
$configDir = Join-Path $HOME ".config"
$asciiArts = Get-ChildItem (Join-Path $configDir "fastfetch/ascii-arts/") -Filter *.txt
$configFile = Join-Path $configDir "fastfetch/config.jsonc"

if ($asciiArts.Count -gt 0) {
    $logoFile = Get-Random -InputObject $asciiArts
    fastfetch -c $configFile --logo "$($logoFile.FullName)"
} else {
    fastfetch -c $configFile
}


Invoke-Expression (&starship init powershell)
