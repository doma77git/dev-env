#!/usr/bin/env pwsh
# === sync-updates.ps1 =========================================
# ROLE:   Apply all pipeline updates — PATH/OneDrive/Env detection
#         Aplikuje všechna vylepšení najednou
# RUN:    ./sync-updates.ps1 -Force
# ==============================================================
param([switch]$Force)

$repo = Split-Path -Parent $PSScriptRoot

# Files to update
$updates = @(
    @{ path = "scripts/10-detect.ps1"; b64 = "" }
    @{ path = "scripts/60-repair.ps1"; b64 = "" }
    @{ path = "scripts/70-test.ps1";   b64 = "" }
)

Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  SYNC — dev-env pipeline updates         ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan

$count = 0
foreach ($u in $updates) {
    $fullPath = Join-Path $repo $u.path
    if (-not (Test-Path $fullPath)) {
        Write-Host "  ❌  $($u.path) — nenalezeno" -ForegroundColor Red
        continue
    }
    if (-not $Force) {
        Write-Host "  ℹ   $($u.path) — přepište s -Force" -ForegroundColor Yellow
        continue
    }
    
    # Backup
    $backup = "$fullPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -Path $fullPath -Destination $backup
    Write-Host "  💾  Záloha: $([IO.Path]::GetFileName($backup))" -ForegroundColor DarkGray
    
    # Decode + write
    $content = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($u.b64))
    Set-Content -Path $fullPath -Value $content -Encoding UTF8 -NoNewline
    Write-Host "  ✅  $($u.path)" -ForegroundColor Green
    $count++
}

if ($Force) {
    Write-Host ""
    Write-Host "  ✅  $count souborů aktualizováno" -ForegroundColor Green
    Write-Host "  ▶  Spusťte: .\scripts\70-test.ps1" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "  ▶  Pro aplikaci: .\sync-updates.ps1 -Force" -ForegroundColor Yellow
}
