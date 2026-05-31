#!/usr/bin/env pwsh
# === bootstrap.ps1 =============================================
# ROLE:   One-liner bootstrap — clone repo + run pipeline
#         Jeden příkaz pro celý dev-env pipeline
# RUN:    irm https://raw.githubusercontent.com/doma77git/dev-env/master/bootstrap.ps1 | iex
# ==============================================================
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$WhatIf,
    [switch]$Quick,
    [switch]$ValidateOnly,
    [switch]$Force
)

$repoUrl = "https://github.com/doma77git/dev-env.git"
$repoDir = "$env:USERPROFILE\.dev-env\repo"
$logDir  = "$env:USERPROFILE\.dev-env\logs"

Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  DEV-ENV PIPELINE — Bootstrap            ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan

# 0. Smoke test — basic prerequisites before clone
Write-Host ""
Write-Host "─── Smoke test ─────────────────────────────────────" -ForegroundColor DarkCyan
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "  ⚠  PowerShell $($PSVersionTable.PSVersion.Major) detected — PS7+ recommended" -ForegroundColor Yellow
    Write-Host "      Some features may not work correctly" -ForegroundColor DarkGray
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "  ❌  Git is not installed" -ForegroundColor Red
    Write-Host "      Install from: https://git-scm.com/downloads" -ForegroundColor Cyan
    Write-Host "      Or run: winget install Git.Git" -ForegroundColor Cyan
    exit 1
} else {
    $gitVer = try { (& git --version 2>&1 | Select-Object -First 1) -join '' } catch { "?" }
    Write-Host "  ✅  Git: $gitVer" -ForegroundColor Green
}
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "  ⚠  winget not found — package installation will be skipped" -ForegroundColor Yellow
    if (-not $ValidateOnly) { Write-Host "      Install from: https://aka.ms/getwinget" -ForegroundColor DarkGray }
}
Write-Host ""

# 1. Clone/pull repo
if (-not (Test-Path $repoDir)) {
    Write-Host "  📦 Klonování repozitáře ..." -ForegroundColor Yellow
    git clone $repoUrl $repoDir 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host "❌ Selhalo klonování" -ForegroundColor Red; exit 1 }
    Write-Host "  ✅ Naklonováno: $repoDir" -ForegroundColor Green
} else {
    Write-Host "  📦 Aktualizace repozitáře ..." -ForegroundColor Yellow
    Push-Location $repoDir
    git pull 2>&1 | Out-Null
    Pop-Location
    Write-Host "  ✅ Aktualizováno" -ForegroundColor Green
}

# 2. Spustit pipeline
Push-Location $repoDir
$menuArgs = @()
if ($WhatIf) { $menuArgs += "-WhatIf" }
if ($Quick)  { $menuArgs += "-TimeoutSeconds"; $menuArgs += "2" }
if ($Force)  { $menuArgs += "-Force" }

Write-Host "  🚀 Spouštím pipeline ..." -ForegroundColor Cyan
if ($ValidateOnly) {
    Write-Host "  🔍 Validate-only: spouštím testy ..." -ForegroundColor Cyan
    & ".\scripts\70-test.ps1" 2>&1
    & ".\scripts\99-validate-bootstrap.ps1" -Quick 2>&1
} elseif ($Quick -or $Force) {
    & ".\scripts\20-install-software.ps1" -IncludeRequired -IncludeRecommended -Force 2>&1
    & ".\scripts\70-test.ps1" 2>&1
} else {
    & ".\scripts\00-menu.ps1" @menuArgs 2>&1
}
Pop-Location
