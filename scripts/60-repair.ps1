#!/usr/bin/env pwsh
# === scripts/60-repair.ps1 ====================================
# ROLE:   Repair common issues — PATH, HOME, OneDrive
#         Oprava běžných problémů
# RUN:    ./60-repair.ps1 -WhatIf      (dry run / suchý běh)
#         ./60-repair.ps1 -Force         (apply / aplikovat)
# ==============================================================
param([switch]$Force, [switch]$WhatIf)

Write-Host ">>> PHASE 60 — ENVIRONMENT REPAIR / OPRAVY" -ForegroundColor Green
$fixes = 0; $issues = 0

# 1. HOME env variable
if (-not $env:HOME) {
    $issues++
    Write-Host "[ISSUE] HOME not set / nenastaveno" -ForegroundColor Red
    if ($Force)   { [Environment]::SetEnvironmentVariable("HOME", $env:USERPROFILE, "User"); Write-Host "  FIXED" -ForegroundColor Green }
    if ($WhatIf)  { Write-Host "  [WHATIF] Would setx HOME=$env:USERPROFILE" -ForegroundColor DarkCyan }
}

# 2. PATH duplicates
$pathEntries = $env:PATH -split ';' | Where-Object { $_ -ne '' }
$dupes = $pathEntries | Group-Object | Where-Object Count -gt 1
if ($dupes) {
    $issues += $dupes.Count
    foreach ($d in $dupes) {
        Write-Host "[ISSUE] PATH duplicita: $($d.Name) (x$($d.Count))" -ForegroundColor Red
    }
    if ($Force)   { Write-Host "  FIX: Run manual — $($dupes.Count) duplicates to clean" -ForegroundColor Yellow }
    if ($WhatIf)  { Write-Host "  [WHATIF] Would deduplicate PATH" -ForegroundColor DarkCyan }
}

# 3. PATH missing entries
$missing = $pathEntries | Where-Object { 
    try { -not (Test-Path ([Environment]::ExpandEnvironmentVariables($_))) } catch { $true }
}
if ($missing) {
    $issues += $missing.Count
    foreach ($m in $missing) {
        Write-Host "[ISSUE] PATH missing: $m" -ForegroundColor Red
    }
    if ($Force)   { Write-Host "  FIX: Run manual — $($missing.Count) missing paths to remove" -ForegroundColor Yellow }
    if ($WhatIf)  { Write-Host "  [WHATIF] Would remove $($missing.Count) missing PATH entries" -ForegroundColor DarkCyan }
}

# 4. OneDrive folder redirects
$redirects = @{}
if (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders") {
    foreach ($n in @("Desktop","Documents","Pictures")) {
        $v = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name $n -ErrorAction SilentlyContinue).$n
        if ($v -and $v -match 'OneDrive') {
            $issues++
            Write-Host "[ISSUE] OneDrive redirects $n → $v" -ForegroundColor Yellow
            if ($Force)   { Write-Host "  FIX: Manually disable OneDrive backup for $n" -ForegroundColor Yellow }
            if ($WhatIf)  { Write-Host "  [WHATIF] Would unlink OneDrive redirect for $n" -ForegroundColor DarkCyan }
        }
    }
}

# 5. SSH keys existence
if (-not (Test-Path "$env:USERPROFILE\.ssh")) {
    $issues++
    Write-Host "[ISSUE] No SSH directory / chybí .ssh" -ForegroundColor Red
    if ($Force)   { New-Item -ItemType Directory -Path "$env:USERPROFILE\.ssh" -Force; Write-Host "  Created" -ForegroundColor Green }
    if ($WhatIf)  { Write-Host "  [WHATIF] Would create ~/.ssh/" -ForegroundColor DarkCyan }
}
$sshKeys = Get-ChildItem "$env:USERPROFILE\.ssh\id_*" -ErrorAction SilentlyContinue
if (-not $sshKeys) {
    $issues++
    Write-Host "[ISSUE] No SSH keys found / chybí SSH klíče" -ForegroundColor Red
    if ($Force)   { Write-Host "  FIX: Run 'ssh-keygen -t ed25519 -C your@email'" -ForegroundColor Yellow }
    if ($WhatIf)  { Write-Host "  [WHATIF] Would suggest ssh-keygen" -ForegroundColor DarkCyan }
}

# Summary
Write-Host ""
if ($issues -eq 0) {
    Write-Host "  ✅  No issues / žádné problémy" -ForegroundColor Green
} else {
    Write-Host "  ⚠  $issues issues found / nalezeno" -ForegroundColor Yellow
    if (-not $Force -and -not $WhatIf) { Write-Host "  Run with -WhatIf or -Force / Spust s -WhatIf nebo -Force" -ForegroundColor Cyan }
Write-Host ""
Write-Host ">>> 60 — environment-repair OK" -ForegroundColor Green
Write-Host "  issues: $issues, proceeding with phase 70" -ForegroundColor DarkGray
}
