#!/usr/bin/env pwsh
# === scripts/undo-last.ps1 ===================================
# ROLE:   Display the last transcript log for manual rollback guidance
#         Zobrazí poslední transcript log pro manuální rollback
# RUN:    ./scripts/undo-last.ps1
# ==============================================================
param([switch]$Pager)

$logsDir = "$env:USERPROFILE\.dev-env\logs"

if (-not (Test-Path $logsDir)) {
    Write-Host "No logs directory found. Nothing to undo." -ForegroundColor Yellow
    Write-Host "Transcripts are saved to ~/.dev-env/logs/ during setup/repair phases." -ForegroundColor DarkGray
    exit 0
}

$latest = Get-ChildItem "$logsDir\setup-*.log" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $latest) {
    Write-Host "No transcript logs found in $logsDir" -ForegroundColor Yellow
    exit 0
}

Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  📝  LAST SETUP/REPAIR LOG               ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  File : $($latest.Name)" -ForegroundColor Gray
Write-Host "  Date : $($latest.LastWriteTime)" -ForegroundColor Gray
Write-Host "  Size : $([math]::Round($latest.Length / 1KB, 1)) KB" -ForegroundColor Gray
Write-Host ""

Write-Host "── Summary of changes ──" -ForegroundColor DarkCyan
Write-Host ""

# Parse transcript for key actions
$content = Get-Content $latest.FullName -Raw -ErrorAction SilentlyContinue
if (-not $content) {
    Write-Host "  Cannot read log file." -ForegroundColor Red
    exit 1
}

# Extract winget installs
$installs = [regex]::Matches($content, "Installing (.+?) \.\.\.", 'Multiline')
$wingetInstalls = [regex]::Matches($content, "winget install.*?--id (\S+)", 'Multiline')
$dirCreates = [regex]::Matches($content, "Created directory.*?(\S+)$", 'Multiline')
$gitChanges = [regex]::Matches($content, "Set: (.+?) <(.+?)>", 'Multiline')
$symlinks = [regex]::Matches($content, "Created symlink: (.+?) -> (.+)", 'Multiline')

$foundAny = $false

if ($installs.Count -gt 0) {
    $foundAny = $true
    Write-Host "  📦 Packages installed:" -ForegroundColor Yellow
    foreach ($m in $installs) { Write-Host "    - $($m.Groups[1].Value)" -ForegroundColor Gray }
    Write-Host "    Undo: winget uninstall <package-id>" -ForegroundColor DarkGray
    Write-Host ""
}

if ($wingetInstalls.Count -gt 0) {
    Write-Host "  📦 Winget packages:" -ForegroundColor Yellow
    foreach ($m in $wingetInstalls) { Write-Host "    - $($m.Groups[1].Value)" -ForegroundColor Gray }
    Write-Host "    Undo: winget uninstall --id <package-id>" -ForegroundColor DarkGray
    Write-Host ""
}

if ($dirCreates.Count -gt 0 -and $dirCreates.Count -le 20) {
    $foundAny = $true
    Write-Host "  📁 Directories created:" -ForegroundColor Yellow
    $shown = @{}
    foreach ($m in $dirCreates) {
        $dir = $m.Groups[1].Value
        if (-not $shown[$dir]) { Write-Host "    - $dir" -ForegroundColor Gray; $shown[$dir] = $true }
    }
    Write-Host "    Undo: Remove-Item <path> (careful!)" -ForegroundColor DarkGray
    Write-Host ""
}

if ($gitChanges.Count -gt 0) {
    $foundAny = $true
    Write-Host "  🔧 Git config changes:" -ForegroundColor Yellow
    foreach ($m in $gitChanges) { Write-Host "    - $($m.Groups[1].Value) <$($m.Groups[2].Value)>" -ForegroundColor Gray }
    Write-Host "    Undo: git config --global --unset <key>" -ForegroundColor DarkGray
    Write-Host ""
}

if (-not $foundAny) {
    Write-Host "  No identifiable changes found in transcript." -ForegroundColor DarkGray
    Write-Host "  Review the full log for details." -ForegroundColor DarkGray
}

Write-Host "── Guidance ──" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Rollback is MANUAL — review each change before undoing." -ForegroundColor Yellow
Write-Host "  Some changes (directory creation, package installs) may have" -ForegroundColor Yellow
Write-Host "  side effects that require manual cleanup." -ForegroundColor Yellow
Write-Host ""

if ($Pager) {
    Write-Host "── Full transcript ──" -ForegroundColor DarkCyan
    Get-Content $latest.FullName | Out-Host -Paging
}

Write-Host "  Full log: $($latest.FullName)" -ForegroundColor Cyan
