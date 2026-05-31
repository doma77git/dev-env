#!/usr/bin/env pwsh
# === scripts/99-validate-bootstrap.ps1 =========================
# ROLE:   Validate entire bootstrap pipeline end-to-end
#         Validace celého bootstrap pipeline
# RUN:    ./99-validate-bootstrap.ps1          (normální běh)
#         ./99-validate-bootstrap.ps1 -Quick   (přeskočit instalace)
# ==============================================================
[CmdletBinding(SupportsShouldProcess=$false)]
param([switch]$Quick)

$ErrorActionPreference = "Stop"
$logDir = Join-Path $env:USERPROFILE ".dev-env" "logs"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$reportFile = Join-Path $env:USERPROFILE ".dev-env" "bootstrap-validation.json"
$logFile = Join-Path $logDir "validate-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

$results = [ordered]@{
    timestamp   = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    hostname    = $env:COMPUTERNAME
    os          = "$((Get-CimInstance Win32_OperatingSystem -EA 0).Caption) build $((Get-CimInstance Win32_OperatingSystem -EA 0).BuildNumber)"
    phases      = [ordered]@{}
    summary     = [ordered]@{ pass = 0; fail = 0; total = 0 }
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $logMsg = "[$ts] [$Level] $Message"
    switch ($Level) {
        "ERROR" { Write-Host $logMsg -ForegroundColor Red }
        "WARN"  { Write-Host $logMsg -ForegroundColor Yellow }
        default { Write-Host $logMsg -ForegroundColor Gray }
    }
    Add-Content -Path $logFile -Value $logMsg -Encoding UTF8
}

function Run-Phase {
    param([string]$Name, [string]$Script, [string]$Args = "", [string]$Description)
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  $Name" -ForegroundColor Cyan
    if ($Description) { Write-Host "║  $Description" -ForegroundColor DarkGray }
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
    
    $start = Get-Date
    $result = [ordered]@{ script = $Script; args = $Args; status = "UNKNOWN"; exitCode = -1; duration = "" }
    
    try {
        if ($Quick -and $Name -match "50-setup|repair -Force") {
            Write-Host "  ⚡  Quick mode — přeskočeno" -ForegroundColor Yellow
            $result.status = "SKIPPED"; $result.exitCode = 0
        } else {
            $fullCmd = if ($Args) { "$Script $Args" } else { $Script }
            Write-Log "Spouštím: $fullCmd" "INFO"
            if ($Args) { & (Join-Path $PSScriptRoot $Script) @(if($Args){$Args -split ' '}) 2>&1 }
            else { & (Join-Path $PSScriptRoot $Script) 2>&1 }
            $result.exitCode = $LASTEXITCODE
            $result.status = if ($LASTEXITCODE -eq 0) { "PASS" } else { "FAIL" }
        }
    } catch {
        $result.status = "ERROR"
        $result.exitCode = 1
        Write-Log "Exception: $_" "ERROR"
    }
    
    $result.duration = "{0:N1}s" -f ((Get-Date) - $start).TotalSeconds
    $results.phases[$Name] = $result
    
    if ($result.status -eq "PASS") { $results.summary.pass++; Write-Host "  ✅  $Name — PASS" -ForegroundColor Green }
    elseif ($result.status -eq "SKIPPED") { Write-Host "  ⏭️  $Name — SKIPPED" -ForegroundColor Yellow }
    else { $results.summary.fail++; Write-Host "  ❌  $Name — FAIL (code $($result.exitCode))" -ForegroundColor Red }
    $results.summary.total++
    
    return ($result.status -eq "PASS" -or $result.status -eq "SKIPPED")
}

Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  BOOTSTRAP VALIDATION                    ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Log "Starting validation, Quick=$Quick" "INFO"

# Fáze 1: Core Check
Run-Phase -Name "00-core-check" -Script "00-core-check.ps1" -Description "PowerShell, Git, network"

# Fáze 2: Detekce
Run-Phase -Name "10-detect" -Script "10-detect.ps1" -Description "OS, PATH, OneDrive, Software"

# Fáze 3: Repair dry-run
Run-Phase -Name "60-repair -WhatIf" -Script "60-repair.ps1" -Args "-WhatIf -SkipBackup" -Description "Suchý běh oprav"

# Fáze 4: Repair skutečný
Run-Phase -Name "60-repair -Force" -Script "60-repair.ps1" -Args "-Force -SkipBackup" -Description "Skutečná oprava"

# Fáze 5: Validační testy
Run-Phase -Name "70-test" -Script "70-test.ps1" -Description "15 testů"

# Fáze 6: Setup suchý běh
Run-Phase -Name "50-setup -WhatIf" -Script "50-setup-home.ps1" -Args "-WhatIf" -Description "Suchý běh instalace"

# Report
$results | ConvertTo-Json -Depth 5 | Out-File $reportFile -Encoding UTF8

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  VALIDATION COMPLETE                     ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Výsledky: $($results.summary.pass)/$($results.summary.total) PASS" -ForegroundColor $(if($results.summary.fail -eq 0){'Green'}else{'Red'})
Write-Host "  Report: $reportFile" -ForegroundColor DarkGray
Write-Host "  Log:    $logFile" -ForegroundColor DarkGray

if ($results.summary.fail -gt 0) {
    Write-Host ""
    Write-Host "  ❌  Selhaly fáze:" -ForegroundColor Red
    foreach ($p in $results.phases.Keys) {
        if ($results.phases[$p].status -eq "FAIL") {
            Write-Host "      - $p (exit $($results.phases[$p].exitCode))" -ForegroundColor Red
        }
    }
    exit 1
}
exit 0
