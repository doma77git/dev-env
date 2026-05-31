#!/usr/bin/env pwsh
# === sync-all.ps1 =============================================
# ROLE:   Self-extracting update for all 3 pipeline scripts
#         Samorozbalovací aktualizace všech 3 skriptů
# RUN:    ./sync-all.ps1 -Force
# ==============================================================
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Force)

$ErrorActionPreference = "Stop"

Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  SYNC-ALL — dev-env pipeline update      ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan

$repo = Split-Path -Parent $PSScriptRoot
$files = @(
    @{ name = "scripts/10-detect.ps1"; b64 = "10DETECT_B64" }
    @{ name = "scripts/60-repair.ps1"; b64 = "60REPAIR_B64" }
    @{ name = "scripts/70-test.ps1";   b64 = "70TEST_B64" }
)

if (-not $Force) {
    Write-Host "  ℹ  Dry-run — použij -Force pro aplikaci" -ForegroundColor Yellow
    Write-Host "  ▶  $($files.Count) soubory:" -ForegroundColor Gray
    foreach ($f in $files) { Write-Host "       $($f.name)" -ForegroundColor Gray }
    exit 0
}

$ok = 0
foreach ($f in $files) {
    $fullPath = Join-Path $repo $f.name
    if (-not (Test-Path $fullPath)) { Write-Host "  ❌  Nenalezeno: $($f.name)" -ForegroundColor Red; continue }
    
    # Backup
    $backup = "$fullPath.backup"
    Copy-Item -Path $fullPath -Destination $backup -Force
    Write-Host "  💾  $($f.name) → .backup" -ForegroundColor DarkGray
    
    # Decode + write
    try {
        $content = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($f.b64))
        Set-Content -Path $fullPath -Value $content -Encoding UTF8 -NoNewline
        Write-Host "  ✅  $($f.name)" -ForegroundColor Green; $ok++
    } catch { Write-Host "  ❌  $($f.name): $_" -ForegroundColor Red }
}

Write-Host ""
if ($ok -eq $files.Count) {
    Write-Host "  ✅  $ok souborů aktualizováno" -ForegroundColor Green
    Write-Host "  ▶  Spusťte: .\scripts\70-test.ps1" -ForegroundColor Cyan
} else { Write-Host "  ❌  $ok / $($files.Count) OK" -ForegroundColor Red }
