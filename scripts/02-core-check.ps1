#!/usr/bin/env pwsh
# === scripts/02-core-check.ps1 =================================
# PHASE: 02 — Core check: PS version, git, connectivity
# ROLE:  Check critical dependencies → report → exit 1 if missing
#        NO automatic installation (rule 3, rule 5)
# RUN:   ./02-core-check.ps1 [-WhatIf]
#        ./02-core-check.ps1 -Force  (CI/CD, expects all OK)
# =====================================================================
param([switch]$WhatIf, [switch]$Force)

$ErrorActionPreference = "Continue"
$failed = 0

Write-Host ">>> PHASE 02 — CORE CHECK / ZÁKLADNÍ KONTROLA" -ForegroundColor Cyan
Write-Host ""

# ─────────────────────────────────────────────────────────────────
# 2.1 — PowerShell version
# ─────────────────────────────────────────────────────────────────
Write-Host "  2.1 PowerShell version" -ForegroundColor Cyan
$psMajor = $PSVersionTable.PSVersion.Major
$psVersion = $PSVersionTable.PSVersion.ToString()

if ($psMajor -ge 7) {
    Write-Host "    ✅ PowerShell $psVersion — OK" -ForegroundColor Green
} else {
    Write-Host "    ❌ Windows PowerShell $psVersion — vyžadujeme 7+" -ForegroundColor Red
    Write-Host ""
    Write-Host "    DOPORUČENÍ:" -ForegroundColor Yellow
    Write-Host "      winget install Microsoft.PowerShell" -ForegroundColor White
    Write-Host "      (nebo: https://github.com/PowerShell/PowerShell/releases)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    Po instalaci spusť znovu: irm <gist> | iex" -ForegroundColor Yellow
    $failed++
}

# ─────────────────────────────────────────────────────────────────
# 2.2 — Git
# ─────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  2.2 Git" -ForegroundColor Cyan
$gitCmd = $null
try { $gitCmd = Get-Command git -ErrorAction Stop } catch {}

if ($gitCmd) {
    $gitVer = & git --version 2>&1 | Select-Object -First 1
    Write-Host "    ✅ $gitVer" -ForegroundColor Green
} else {
    Write-Host "    ⬚ Git není nainstalován" -ForegroundColor Yellow
    Write-Host "    DOPORUČENÍ: winget install Git.Git" -ForegroundColor DarkGray
    Write-Host "    (není kritické — pipeline použije remote fallback)" -ForegroundColor DarkGray
    # NENÍ exit 1 — git se rozhoduje v Phase 30 (clone), nikoli zde
}

# ─────────────────────────────────────────────────────────────────
# 2.3 — Connectivity (gist reachable?)
# ─────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  2.3 Connectivity" -ForegroundColor Cyan
$gistTestUrl = "https://gist.githubusercontent.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1"
try {
    $null = Invoke-WebRequest -Uri $gistTestUrl -Method Head -TimeoutSec 5 -ErrorAction Stop
    Write-Host "    ✅ Gist reachable — OK" -ForegroundColor Green
} catch {
    Write-Host "    ❌ Cannot reach GitHub Gist (offline / proxy / firewall)" -ForegroundColor Red
    Write-Host ""
    Write-Host "    DOPORUČENÍ:" -ForegroundColor Yellow
    Write-Host "      1. Zkontroluj připojení k internetu" -ForegroundColor DarkGray
    Write-Host "      2. Pokud jsi za proxy, nastav:" -ForegroundColor DarkGray
    Write-Host '         $env:HTTP_PROROXY = "http://proxy:port"' -ForegroundColor White
    Write-Host '         $env:HTTPS_PROXY = "http://proxy:port"' -ForegroundColor White
    Write-Host "      3. Zkus: irm $gistTestUrl | Select-Object -First 1" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    Bez přístupu ke gistu nelze pokračovat." -ForegroundColor Red
    $failed++
}

# ─────────────────────────────────────────────────────────────────
# 2.4 — Summary
# ─────────────────────────────────────────────────────────────────
Write-Host ""
if ($failed -gt 0) {
    Write-Host ">>> 02 — core check FAIL ($failed critical issue(s))" -ForegroundColor Red
    Write-Host "  Odstraň výše uvedené problémy a spusť znovu." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host ">>> 02 — core check OK" -ForegroundColor Green
    Write-Host "  All critical dependencies met, proceeding" -ForegroundColor DarkGray
    exit 0
}
