#!/usr/bin/env pwsh
# === scripts/setup-home.ps1 ===================================
# ROLE:   Home PC setup — winget install + symlink + folders
#         Instalace domácího PC
# RUN:    ./setup-home.ps1 -WhatIf       (dry run / suchý běh)
#         ./setup-home.ps1 -Force          (apply / aplikovat)
# ==============================================================
param([switch]$Force, [switch]$WhatIf)

$profile = Get-Content (Join-Path $PSScriptRoot ".." "profiles" "home.json") -Raw | ConvertFrom-Json

Write-Host "=== SETUP HOME ===" -ForegroundColor Green
Write-Host ""

# 1. HOME env variable
Write-Host "[1/5] HOME environment variable" -ForegroundColor Cyan
if ($env:HOME -and $env:HOME -ne $env:USERPROFILE) {
    Write-Host "  HOME = $env:HOME" -ForegroundColor Green
} elseif ($env:HOME -eq $env:USERPROFILE) {
    Write-Host "  HOME = USERPROFILE (OK)" -ForegroundColor Yellow
} else {
    Write-Host "  HOME not set / nenastaveno" -ForegroundColor Red
    if ($Force) {
        Write-Host "  Setting HOME = $env:USERPROFILE" -ForegroundColor Yellow
        [Environment]::SetEnvironmentVariable("HOME", $env:USERPROFILE, "User")
    } elseif ($WhatIf) {
        Write-Host "  [WHATIF] Would set HOME = $env:USERPROFILE" -ForegroundColor DarkCyan
    }
}

# 2. Directories / složky
Write-Host "[2/5] Directories / složky" -ForegroundColor Cyan
$dirs = @(
    "~\dev\projects\osobni",
    "~\dev\projects\ppg",
    "~\dev\projects\lab",
    "~\.config\powershell",
    "~\bin",
    "~\.dev-env\config",
    "~\Documents\downloads\_temp",
    "~\Documents\downloads\keep",
    "~\Documents\docs\navody",
    "~\Documents\docs\architektura",
    "~\Documents\chat-exports"
)
foreach ($d in $dirs) {
    $expanded = [Environment]::ExpandEnvironmentVariables($d.Replace("~", $env:USERPROFILE))
    if (Test-Path $expanded) {
        Write-Host "  OK  $d" -ForegroundColor Green
    } else {
        Write-Host "  NEW $d" -ForegroundColor Yellow
        if ($Force)   { New-Item -ItemType Directory -Path $expanded -Force | Out-Null }
        if ($WhatIf)  { Write-Host "  [WHATIF] Would create $d" -ForegroundColor DarkCyan }
    }
}

# 3. Winget / balíčky
Write-Host "[3/5] Packages / balíčky (winget)" -ForegroundColor Cyan
$packages = @(
    "Git.Git",
    "Microsoft.PowerShell",
    "Microsoft.WindowsTerminal",
    "Microsoft.VisualStudioCode",
    "Python.Python.3.12",
    "OpenJS.NodeJS.LTS",
    "GitHub.cli",
    "Docker.DockerDesktop",
    "7zip.7zip",
    "Neovim.Neovim",
    "Starship.Starship"
)
foreach ($pkg in $packages) {
    $installed = winget list --id $pkg 2>$null | Select-String -SimpleMatch $pkg
    if ($installed) {
        Write-Host "  OK  $pkg" -ForegroundColor Green
    } else {
        Write-Host "  MISS $pkg" -ForegroundColor Yellow
        if ($Force)  { Write-Host "  Installing $pkg ..."; winget install --id $pkg --accept-source-agreements }
        if ($WhatIf) { Write-Host "  [WHATIF] Would install $pkg" -ForegroundColor DarkCyan }
    }
}

# 4. Symlink configs / konfigy
Write-Host "[4/5] Config symlinks / symlinky" -ForegroundColor Cyan
& "$PSScriptRoot\link-configs.ps1" -WhatIf:$WhatIf -Force:$Force

# 5. Git config / globální nastavení
Write-Host "[5/5] Git identity / identita" -ForegroundColor Cyan
$gitName  = $profile.identity.git.name
$gitEmail = $profile.identity.git.email
if ($Force) {
    git config --global user.name "$gitName"
    git config --global user.email "$gitEmail"
    Write-Host "  Set: $gitName <$gitEmail>" -ForegroundColor Green
} elseif ($WhatIf) {
    Write-Host "  [WHATIF] Would set: $gitName <$gitEmail>" -ForegroundColor DarkCyan
} else {
    $current = git config --global user.name 2>$null
    $currentEmail = git config --global user.email 2>$null
    Write-Host "  Current: $current <$currentEmail>" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== DONE ===" -ForegroundColor Green
if (-not $Force -and -not $WhatIf) { Write-Host "  Run with -WhatIf or -Force / Spust s -WhatIf nebo -Force" -ForegroundColor Cyan }
