#!/usr/bin/env pwsh
# === scripts/50-setup.ps1 ======================================
# PHASE: 50 — Setup dispatcher
# ROLE:  Check profile → dispatch to 50-setup-<profile>.ps1
#        Respect -WhatIf, -Force, Confirm-Action
#        CRITICAL: never install without confirm (rule 5)
#        VŽDY dry-run first, then confirm, then apply
# RUN:   ./50-setup.ps1 [-WhatIf] [-Force] [-ProfileName home]
# =====================================================================
param(
    [switch]$WhatIf,
    [switch]$Force,
    [string]$ProfileName = "home"
)

$ErrorActionPreference = "Continue"

# Dot-source Confirm-Action
$confirmPath = Join-Path $PSScriptRoot "Confirm-Action.ps1"
if (Test-Path $confirmPath) { . $confirmPath }

Write-Host ">>> PHASE 50 — PACKAGE SETUP / INSTALACE" -ForegroundColor Green
Write-Host "  Profile: $ProfileName" -ForegroundColor Cyan
Write-Host "  Mode: $(
    if ($Force) { 'Force — will ask for each category' }
    elseif ($WhatIf) { 'Dry-run — nothing will change' }
    else { 'Interactive (use -Force for unattended)' }
)" -ForegroundColor $(if ($Force) { 'Yellow' } elseif ($WhatIf) { 'Magenta' } else { 'Cyan' })

# ─────────────────────────────────────────────────────────────────
# 50.1 — Resolve setup script by profile
# ─────────────────────────────────────────────────────────────────
$setupScript = Join-Path $PSScriptRoot "50-setup-$ProfileName.ps1"
if (-not (Test-Path $setupScript)) {
    Write-Host "  ⚠ No setup script for profile '$ProfileName'" -ForegroundColor Yellow
    Write-Host "  Available: home, work, lab" -ForegroundColor DarkGray
    exit 1
}

# ─────────────────────────────────────────────────────────────────
# 50.2 — Run dry-run first (VŽDY)
# ─────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ── Dry-run: showing what would change ──" -ForegroundColor Magenta
& $setupScript -WhatIf

# If dry-run only, stop here
if ($WhatIf) {
    Write-Host ""
    Write-Host ">>> 50 — package-setup OK (dry-run only)" -ForegroundColor Green
    Write-Host "  Run with -Force to apply changes" -ForegroundColor Cyan
    exit 0
}

# ─────────────────────────────────────────────────────────────────
# 50.3 — Ask for confirmation (unless -Force without -Confirm)
# ─────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ── Confirm ──" -ForegroundColor Yellow

$proceed = $Force
if (-not $proceed -and (Get-Command Confirm-Action -ErrorAction SilentlyContinue)) {
    $proceed = Confirm-Action "Apply changes for profile '$ProfileName'?" 5
} elseif (-not $proceed) {
    Write-Host "  Confirm-Action not available. Run with -Force to apply." -ForegroundColor Yellow
}

# ─────────────────────────────────────────────────────────────────
# 50.4 — Apply (if confirmed)
# ─────────────────────────────────────────────────────────────────
if ($proceed) {
    Write-Host ""
    Write-Host "  ── Applying changes ──" -ForegroundColor Green
    & $setupScript -Force
    Write-Host ""
    Write-Host ">>> 50 — package-setup OK (applied)" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "  SKIPPED — run manually:" -ForegroundColor Yellow
    Write-Host "    ./50-setup-$ProfileName.ps1 -Force" -ForegroundColor Cyan
    Write-Host ""
    Write-Host ">>> 50 — package-setup SKIPPED" -ForegroundColor Yellow
}
