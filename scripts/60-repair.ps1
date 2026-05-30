#!/usr/bin/env pwsh
# === scripts/60-repair.ps1 ====================================
# ROLE:   Repair common issues — PATH, HOME, OneDrive
#         Oprava běžných problémů
# RUN:    ./60-repair.ps1 -WhatIf      (dry run / suchý běh)
#         ./60-repair.ps1 -Force       (apply / aplikovat)
#         ./60-repair.ps1 -Confirm     (potvrzovat každou změnu)
# ==============================================================
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Force)

Write-Host ">>> PHASE 60 — ENVIRONMENT REPAIR / OPRAVY" -ForegroundColor Green
$fixes = 0; $issues = 0

# 1. HOME env variable
if (-not $env:HOME) {
    $issues++
    Write-Host "[ISSUE] HOME not set / nenastaveno" -ForegroundColor Red
    if ($PSCmdlet.ShouldProcess("HOME=$env:USERPROFILE", "Set HOME environment variable")) {
        [Environment]::SetEnvironmentVariable("HOME", $env:USERPROFILE, "User")
        Write-Host "  FIXED" -ForegroundColor Green
    }
}

# 2. PATH duplicates — detection only (manual fix via PATH cleanup)
$pathEntries = $env:PATH -split ';' | Where-Object { $_ -ne '' }
$dupes = $pathEntries | Group-Object | Where-Object Count -gt 1
if ($dupes) {
    $issues += $dupes.Count
    foreach ($d in $dupes) {
        Write-Host "[ISSUE] PATH duplicita: $($d.Name) (x$($d.Count))" -ForegroundColor Red
    }
    if ($PSCmdlet.ShouldProcess("$($dupes.Count) duplicate PATH entries", "Deduplicate PATH")) {
        Write-Host "  FIX: Manual cleanup required — edit PATH in System Properties" -ForegroundColor Yellow
    }
}

# 3. PATH missing entries — detection only (manual fix)
$missing = $pathEntries | Where-Object { 
    try { -not (Test-Path ([Environment]::ExpandEnvironmentVariables($_))) } catch { $true }
}
if ($missing) {
    $issues += $missing.Count
    foreach ($m in $missing) {
        Write-Host "[ISSUE] PATH missing: $m" -ForegroundColor Red
    }
    if ($PSCmdlet.ShouldProcess("$($missing.Count) missing PATH entries", "Remove missing PATH entries")) {
        Write-Host "  FIX: Manual cleanup required — remove missing entries from PATH" -ForegroundColor Yellow
    }
}

# 4. OneDrive folder redirects — detection + recommendation
if (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders") {
    foreach ($n in @("Desktop","Documents","Pictures")) {
        $v = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name $n -ErrorAction SilentlyContinue).$n
        if ($v -and $v -match 'OneDrive') {
            $issues++
            Write-Host "[ISSUE] OneDrive redirects $n → $v" -ForegroundColor Yellow
            if ($PSCmdlet.ShouldProcess("$n → local folder", "Unlink OneDrive redirect")) {
                Write-Host "  FIX: Manually disable OneDrive backup for $n in OneDrive Settings" -ForegroundColor Yellow
            }
        }
    }
}

# 5. SSH keys existence
if (-not (Test-Path "$env:USERPROFILE\.ssh")) {
    $issues++
    Write-Host "[ISSUE] No SSH directory / chybí .ssh" -ForegroundColor Red
    if ($PSCmdlet.ShouldProcess("~/.ssh/", "Create SSH directory")) {
        New-Item -ItemType Directory -Path "$env:USERPROFILE\.ssh" -Force | Out-Null
        Write-Host "  Created ~/.ssh/" -ForegroundColor Green
    }
}
$sshKeys = Get-ChildItem "$env:USERPROFILE\.ssh\id_*" -ErrorAction SilentlyContinue
if (-not $sshKeys) {
    $issues++
    Write-Host "[ISSUE] No SSH keys found / chybí SSH klíče" -ForegroundColor Red
    Write-Host "  Fix: ssh-keygen -t ed25519 -C your@email" -ForegroundColor Cyan
}

# Summary
Write-Host ""
if ($issues -eq 0) {
    Write-Host "  ✅  No issues / žádné problémy" -ForegroundColor Green
} else {
    Write-Host "  ⚠  $issues issues found / nalezeno" -ForegroundColor Yellow
    if (-not $Force -and -not $WhatIf) { Write-Host "  Run with -WhatIf or -Force / Spust s -WhatIf nebo -Force" -ForegroundColor Cyan }
}
Write-Host ""
Write-Host ">>> 60 — environment-repair OK" -ForegroundColor Green
Write-Host "  issues: $issues, proceeding with phase 70" -ForegroundColor DarkGray
