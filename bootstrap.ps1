#!/usr/bin/env pwsh
# === bootstrap.ps1 =============================================
# ROLE:   One-liner bootstrap — clone repo + run pipeline
#         Jeden příkaz pro celý dev-env pipeline
# RUN:    irm .../v1.0.0/bootstrap.ps1 | iex
#         irm .../v1.0.0/bootstrap.ps1 | iex -WhatIf
#         irm .../v1.0.0/bootstrap.ps1 | iex -Quick
# ==============================================================
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$WhatIf,
    [switch]$Quick,          # Rychlý mód (3s timeout, plná instalace)
    [switch]$ValidateOnly,   # Jen testy, žádná změna
    [switch]$Force           # Přepsat safeMode
)

# ─── PS5 fallback ─────────────────────────────────────────────
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║  POWERSHELL 5.1 DETEKOVÁN               ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Tento bootstrap vyžaduje PowerShell 7+." -ForegroundColor White
    Write-Host "  PS5 fallback: 00-bootstrap-fallback.ps1" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Ruční postup:" -ForegroundColor Cyan
    Write-Host "  1. winget install Microsoft.PowerShell" -ForegroundColor White
    Write-Host "  2. Restartuj PowerShell a spusť znovu" -ForegroundColor White
    Write-Host "  3. Nebo: https://github.com/PowerShell/PowerShell/releases" -ForegroundColor DarkGray
    exit 1
}

$repoUrl = "https://github.com/doma77git/dev-env.git"
$repoDir = Join-Path $env:USERPROFILE ".dev-env" "repo"

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  DEV-ENV PIPELINE — Bootstrap v1.0.0    ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan

# ─── 0. Smoke test ────────────────────────────────────────────
Write-Host ""; Write-Host "─── Smoke test ─────────────────────────────────────" -ForegroundColor DarkCyan
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "  ❌  Git is not installed" -ForegroundColor Red
    Write-Host "      Install: winget install Git.Git" -ForegroundColor Cyan; exit 1
} else {
    $gv = try { (& git --version 2>&1 | Select-Object -First 1) -join '' } catch { "?" }
    Write-Host "  ✅  Git: $gv" -ForegroundColor Green
}
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "  ⚠  winget not found — package installation skipped" -ForegroundColor Yellow
}
Write-Host ""

# ─── 1. Clone/pull repo ───────────────────────────────────────
if (-not (Test-Path $repoDir)) {
    Write-Host "  📦 Klonování ..." -NoNewline -ForegroundColor Yellow
    git clone $repoUrl $repoDir 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host " FAIL" -ForegroundColor Red; exit 1 }
    Write-Host " OK → $repoDir" -ForegroundColor Green
} else {
    Write-Host "  📦 Pull ..." -NoNewline -ForegroundColor Yellow
    Push-Location $repoDir; git pull 2>&1 | Out-Null; Pop-Location
    Write-Host " OK" -ForegroundColor Green
}

# ─── 2. Detekce režimu ────────────────────────────────────────
$autoMode = $Quick -or $ValidateOnly -or $Force -or $env:CI -or (-not [Environment]::UserInteractive)
Push-Location $repoDir

if ($ValidateOnly) {
    Write-Host "  🔍 Validate-only: spouštím testy ..." -ForegroundColor Cyan
    & ".\scripts\70-test.ps1" 2>&1
    & ".\scripts\99-validate-bootstrap.ps1" -Quick 2>&1
    Pop-Location; exit $LASTEXITCODE
}

if ($autoMode) {
    Write-Host "  🤖 Auto-mode: instalace + testy" -ForegroundColor Cyan
    & ".\scripts\20-install-software.ps1" -IncludeRequired -IncludeRecommended -Force:$Force 2>&1
    & ".\scripts\70-test.ps1" 2>&1
    Pop-Location; exit $LASTEXITCODE
}

# ─── 3. Interaktivní režim — 3s countdown ───────────────────
Write-Host "  ⏳  Spouštím za 3s (stisk klávesy = menu) ..." -ForegroundColor Yellow
$keyPressed = $false
for ($i = 3; $i -gt 0; $i--) {
    Write-Host "`r     $i ..." -NoNewline
    if ([Console]::KeyAvailable) { $keyPressed = $true; [Console]::ReadKey($true) | Out-Null; break }
    Start-Sleep -Seconds 1
}

if ($keyPressed) {
    Write-Host "`r  🎯  Otevírám menu ..." -ForegroundColor Green
    & ".\scripts\00-menu.ps1" 2>&1
} else {
    Write-Host "`r  🚀  Automatická instalace ..." -ForegroundColor Green
    & ".\scripts\20-install-software.ps1" -IncludeRequired -IncludeRecommended 2>&1
    & ".\scripts\70-test.ps1" 2>&1
}

Pop-Location
exit $LASTEXITCODE
