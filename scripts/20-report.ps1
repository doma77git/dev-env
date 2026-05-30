#!/usr/bin/env pwsh
# === scripts/20-report.ps1 ====================================
# ROLE:   Display inventory report + save JSON to ~/.dev-env/
#         Zobrazení reportu + uložení
# INPUT:  $DetectReport from 10-detect.ps1 (script scope)
#         OR imports from last saved machines.json
# RUN:    ./20-report.ps1               (after 10-detect.ps1)
#         ./20-report.ps1 -FromCache    (použít poslední uložený report)
# ==============================================================
[CmdletBinding(SupportsShouldProcess=$false)]
param([switch]$FromCache)

$ErrorActionPreference = "Continue"
$envDir = Join-Path $env:USERPROFILE ".dev-env"

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  PHASE 20 — INVENTORY REPORT             ║" -ForegroundColor Cyan
Write-Host "║  Výsledek detekce                        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan

# ─── Load report ──────────────────────────────────────────
$report = $null

# Priority 1: from script scope (set by 10-detect.ps1)
if (-not $FromCache -and (Get-Variable -Name DetectReport -Scope Script -ErrorAction SilentlyContinue)) {
    $report = $script:DetectReport
}

# Priority 2: from cache (last machines.json entry for this machine)
if (-not $report -and $FromCache) {
    $machinesFile = Join-Path $envDir "machines.json"
    if (Test-Path $machinesFile) {
        try {
            $machines = @(Get-Content $machinesFile -Raw | ConvertFrom-Json)
            $hostname  = $env:COMPUTERNAME
            $username  = $env:USERNAME
            $domain    = $env:USERDOMAIN
            $fp = -join (([Security.Cryptography.SHA256]::Create().ComputeHash(
                [Text.Encoding]::UTF8.GetBytes("$hostname|$username|$domain")
            )) | ForEach-Object { $_.ToString("x2") })
            $report = $machines | Where-Object { $_.fingerprint -eq $fp } | Select-Object -Last 1
        } catch {}
    }
}

if (-not $report) {
    Write-Host "  ❌  No report data available." -ForegroundColor Red
    Write-Host "      Run scripts/10-detect.ps1 first, or use -FromCache" -ForegroundColor Yellow
    Write-Host ""
    Write-Host ">>> 20 — inventory-report FAIL (exit 1)" -ForegroundColor Red
    exit 1
}

# ─── Display status ────────────────────────────────────────
$icon = @{ "new"="🔴"; "same"="🟢"; "os-changed"="🟠"; "tools-changed"="🟡" }
$status = $report.status

Write-Host ""
Write-Host "  $($icon[$status])  $($status.ToUpper())" -ForegroundColor White
if ($report.changes -and $report.changes.Count -gt 0) {
    foreach ($c in $report.changes) {
        Write-Host "     $c" -ForegroundColor Yellow
    }
}
Write-Host ""
Write-Host "  REPO : $($report.meta.repo)" -ForegroundColor Cyan
Write-Host "  HOST : $($report.hostname)" -ForegroundColor Gray
Write-Host "  OS   : $($report.os.caption) (build $($report.os.build))" -ForegroundColor Gray
Write-Host "  TOOLS: $(($report.tools.PSObject.Properties | Where-Object { $_.Value -ne $null }).Count) detected" -ForegroundColor Gray

# ─── Save JSON — append to machines.json ──────────────────
$reportPath = Join-Path $envDir "report-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').json"
$json = $report | ConvertTo-Json -Depth 6
$json | Set-Content -Path $reportPath -Encoding UTF8

$machinesFile = Join-Path $envDir "machines.json"
$machines = @()
if (Test-Path $machinesFile) {
    try { $machines = @(Get-Content $machinesFile -Raw | ConvertFrom-Json) } catch {}
    $machines = @($machines)
}
$machines += $report
$machines | ConvertTo-Json -Depth 6 | Set-Content -Path $machinesFile -Encoding UTF8

Write-Host "  RPT  : $reportPath" -ForegroundColor DarkGray
Write-Host "  JSON saved to machines.json" -ForegroundColor DarkGray

# Export for next phase
$script:InventoryReport = $report

Write-Host ""
Write-Host ">>> 20 — inventory-report OK" -ForegroundColor Green
