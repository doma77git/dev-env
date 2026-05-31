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
    [switch]$Force
)

$repoUrl = "https://github.com/doma77git/dev-env.git"
$repoDir = "$env:USERPROFILE\.dev-env\repo"
$logDir  = "$env:USERPROFILE\.dev-env\logs"

Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  DEV-ENV PIPELINE — Bootstrap            ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan

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
if ($Quick -or $Force) {
    & ".\scripts\20-install-software.ps1" -IncludeRequired -IncludeRecommended -Force:@($Force -or $Quick)[0] 2>&1
    & ".\scripts\70-test.ps1" 2>&1
} else {
    & ".\scripts\00-menu.ps1" @menuArgs 2>&1
}
Pop-Location
