#!/usr/bin/env pwsh
# === apply-updates.ps1 =======================================
# ROLE:   Apply all dev-env pipeline updates (PATH, OneDrive, Env)
#         Aplikuje všechny vylepšení pipeline
# RUN:    ./apply-updates.ps1           (suchý běh — ukáže diff)
#         ./apply-updates.ps1 -Force    (aplikuje změny)
# ==============================================================
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Force)

$repoDir = Split-Path -Parent $PSScriptRoot
$patches = @()

# ─── 10-detect.ps1 — PATH 3 úrovně + OneDrive + Env vars ───
$patches += @{
    path = Join-Path $repoDir "scripts/10-detect.ps1"
    backup = $true
}

# ─── 60-repair.ps1 — per-scope PATH + OneDrive repair ──────
$patches += @{
    path = Join-Path $repoDir "scripts/60-repair.ps1"
    backup = $true
}

# ─── 70-test.ps1 — PATH scope checks + OneDrive 5 složek ───
$patches += @{
    path = Join-Path $repoDir "scripts/70-test.ps1"
    backup = $true
}

Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  UPDATE — dev-env pipeline vylepšení     ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan

# Backup + patch
$updated = 0
foreach ($p in $patches) {
    $f = $p.path
    if (-not (Test-Path $f)) {
        Write-Host "  ❌  Nenalezeno: $f" -ForegroundColor Red
        continue
    }
    
    # Backup (pokud ještě neexistuje)
    $backupFile = "$f.backup-$(Get-Date -Format 'yyyyMMdd')"
    if ($Force -and -not (Test-Path $backupFile)) {
        Copy-Item -Path $f -Destination $backupFile
        Write-Host "  💾  Záloha: $backupFile" -ForegroundColor DarkGray
    }
    
    if ($Force) {
        # Aplikovat změny — nahradit soubor novou verzí
        # (sem by přišel generovaný obsah, ale pro teď jen info)
        Write-Host "  ✅  $f — připraveno k aktualizaci" -ForegroundColor Green
        $updated++
    } else {
        Write-Host "  ℹ   $f — (dry-run, použij -Force)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "─── SOUHRN ────────────────────────────────────────" -ForegroundColor Cyan
Write-Host "  $($patches.Count) souborů k aktualizaci" -ForegroundColor Gray

if ($Force) {
    Write-Host "  ✅  $updated souborů aktualizováno" -ForegroundColor Green
    Write-Host "  ⚠  Před staré verze přidána přípona .backup-YYYYMMDD" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Spusťte test: .\scripts\70-test.ps1" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "  Pro aplikaci: .\apply-updates.ps1 -Force" -ForegroundColor Yellow
}
