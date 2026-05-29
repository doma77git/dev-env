#!/usr/bin/env pwsh
# === scripts/link-configs.ps1 =================================
# ROLE:   Symlink configs from repo into ~/.config/ and ~/
#         Symlinky konfigů z repa do domovské složky
# RUN:    ./link-configs.ps1 -WhatIf
#         ./link-configs.ps1 -Force
# ==============================================================
param([switch]$Force, [switch]$WhatIf)

$repoRoot  = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$configsDir = Join-Path $repoRoot "configs"
$home       = $env:USERPROFILE

Write-Host "=== LINK CONFIGS ===" -ForegroundColor Green
Write-Host "  Repo: $repoRoot" -ForegroundColor DarkGray
Write-Host ""

$links = @(
    @{ From = "configs\git\.gitconfig";          To = "~\.gitconfig" },
    @{ From = "configs\pwsh\profile.ps1";        To = "~\Documents\PowerShell\profile.ps1" }
)

foreach ($link in $links) {
    $from = Join-Path $repoRoot $link.From
    $to   = $link.To.Replace("~", $home)

    if (Test-Path $to) {
        $existing = (Get-Item $to).Target
        if ($existing -eq $from) {
            Write-Host "  OK  $($link.To) → repo" -ForegroundColor Green
        } else {
            Write-Host "  ⚠   $($link.To) exists but points elsewhere / existuje ale ukazuje jinam" -ForegroundColor Yellow
            if ($Force)   {
                $backup = "$to.bak-$(Get-Date -Format 'yyyyMMddHHmmss')"
                Move-Item $to $backup -Force
                Write-Host "  Backed up → $backup" -ForegroundColor DarkGray
                New-Item -ItemType SymbolicLink -Path $to -Target $from -Force | Out-Null
                Write-Host "  LINKED" -ForegroundColor Green
            }
            if ($WhatIf)  { Write-Host "  [WHATIF] Would relink → $from" -ForegroundColor DarkCyan }
        }
    } else {
        Write-Host "  NEW $($link.To)" -ForegroundColor Yellow
        $parent = Split-Path $to -Parent
        if (-not (Test-Path $parent)) {
            if ($Force)   { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            if ($WhatIf)  { Write-Host "  [WHATIF] Would create $parent" -ForegroundColor DarkCyan }
        }
        if ($Force)   { 
            try { New-Item -ItemType SymbolicLink -Path $to -Target $from -Force | Out-Null; Write-Host "  LINKED" -ForegroundColor Green }
            catch { Write-Host "  FAIL (need admin for symlink?): $_" -ForegroundColor Red; Write-Host "  Fallback: copy item" -ForegroundColor Yellow; Copy-Item $from $to -Force }
        }
        if ($WhatIf)  { Write-Host "  [WHATIF] Would symlink $from → $to" -ForegroundColor DarkCyan }
    }
}

Write-Host ""
Write-Host "=== DONE ===" -ForegroundColor Green
