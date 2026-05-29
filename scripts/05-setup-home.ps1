#!/usr/bin/env pwsh
# === scripts/05-setup-home.ps1 ================================
# ROLE:   Home PC setup — winget install + symlink + folders
#         Instalace domácího PC
# RUN:    ./05-setup-home.ps1 -WhatIf    (dry run / suchý běh)
#         ./05-setup-home.ps1 -Force       (apply / aplikovat)
# ==============================================================
param([switch]$Force, [switch]$WhatIf)

$profile = Get-Content (Join-Path $PSScriptRoot ".." "profiles" "home.json") -Raw | ConvertFrom-Json

Write-Host ">>> PHASE 05/8 — PACKAGE SETUP (home) / INSTALACE" -ForegroundColor Green
Write-Host "  Home PC — winget install, folders, git config, autocrlf" -ForegroundColor DarkGray
Write-Host ""

# 1. HOME env variable
Write-Host "5.1 HOME environment variable" -ForegroundColor Cyan
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
Write-Host "5.2 Directories / složky" -ForegroundColor Cyan
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
Write-Host "5.3 Packages / balíčky (winget)" -ForegroundColor Cyan
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
Write-Host "5.4 Config symlinks / symlinky" -ForegroundColor Cyan
& "$PSScriptRoot\link-configs.ps1" -WhatIf:$WhatIf -Force:$Force

# 5. Git config / globální nastavení
Write-Host "5.5 Git identity / identita" -ForegroundColor Cyan
# Resolve identity: saved > git-config > profile default (same priority as profile.ps1)
$identityFile = Join-Path $env:USERPROFILE ".dev-env" "config" "identity.json"
$savedId = if (Test-Path $identityFile) { try { Get-Content $identityFile -Raw | ConvertFrom-Json } catch { $null } } else { $null }
if ($savedId -and $savedId.git.email) {
    $gitName  = $savedId.git.name
    $gitEmail = $savedId.git.email
    Write-Host "  Using saved identity: $gitName <$gitEmail>" -ForegroundColor DarkCyan
} else {
    $gitCfgName  = try { git config --global user.name  2>$null } catch { $null }
    $gitCfgEmail = try { git config --global user.email 2>$null } catch { $null }
    if ($gitCfgName -and $gitCfgEmail -and $gitCfgEmail -ne 'jan@novak.cz' -and $gitCfgEmail -ne 'jan.novak@ppg.com') {
        $gitName  = $gitCfgName
        $gitEmail = $gitCfgEmail
        Write-Host "  Using git-config identity: $gitName <$gitEmail>" -ForegroundColor DarkCyan
    } else {
        $gitName  = $profile.identity.git.name
        $gitEmail = $profile.identity.git.email
        Write-Host "  Using profile default: $gitName <$gitEmail> (PLACEHOLDER)" -ForegroundColor Yellow
    }
}
if ($Force) {
    git config --global user.name "$gitName"
    git config --global user.email "$gitEmail"
    Write-Host "  Set: $gitName <$gitEmail>" -ForegroundColor Green
    # Save identity so profile.ps1 detects it on next run
    $identityFile = Join-Path $env:USERPROFILE ".dev-env" "config" "identity.json"
    $null = New-Item -ItemType Directory -Path (Split-Path $identityFile -Parent) -Force
    @{ git = @{ name = $gitName; email = $gitEmail } } | ConvertTo-Json | Set-Content $identityFile -Encoding UTF8
    Write-Host "  Saved → ~/.dev-env/config/identity.json" -ForegroundColor DarkCyan
} elseif ($WhatIf) {
    Write-Host "  [WHATIF] Would set: $gitName <$gitEmail>" -ForegroundColor DarkCyan
} else {
    $current = git config --global user.name 2>$null
    $currentEmail = git config --global user.email 2>$null
    Write-Host "  Current: $current <$currentEmail>" -ForegroundColor Yellow
}

# 6. Git autocrlf / konce řádků
Write-Host "5.6 Git core.autocrlf / konce řádků" -ForegroundColor Cyan
$currentAutocrlf = git config --global core.autocrlf 2>$null
if ($currentAutocrlf -eq "input") {
    Write-Host "  OK  core.autocrlf = input" -ForegroundColor Green
} else {
    Write-Host "  CHG core.autocrlf = $($currentAutocrlf ?? 'not set') → input" -ForegroundColor Yellow
    if ($Force) {
        git config --global core.autocrlf input
        Write-Host "  Set core.autocrlf = input" -ForegroundColor DarkCyan
    }
    if ($WhatIf) { Write-Host "  [WHATIF] Would set core.autocrlf = input" -ForegroundColor DarkCyan }
}

Write-Host ""
Write-Host ""
Write-Host ">>> 05 — package-setup (home) OK" -ForegroundColor Green
if ($Force)   { Write-Host "  packages installed, proceeding with phase 06" -ForegroundColor DarkGray }
if ($WhatIf)  { Write-Host "  dry-run complete, review above then run with -Force" -ForegroundColor DarkGray }
if (-not $Force -and -not $WhatIf) { Write-Host "  review above then run with -WhatIf or -Force" -ForegroundColor DarkGray }
Write-Host "=== DONE ===" -ForegroundColor Green
