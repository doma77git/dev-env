#!/usr/bin/env pwsh
# === scripts/TEMPLATE.ps1 =====================================
# ROLE:   One-line description / Český popis
# RUN:    ./TEMPLATE.ps1 [-WhatIf] [-Force] [-Confirm]
# INPUT:  $WhatIf (preview), $Force (skip confirmations)
# OUTPUT: Log file ~/.dev-env/logs/TEMPLATE-*.log
# ==============================================================
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Force)

# ─── 1. LOGGING ───────────────────────────────────────────────
$logDir = Join-Path $env:USERPROFILE ".dev-env" "logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = Join-Path $logDir "TEMPLATE-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    Add-Content -Path $logFile -Value "[$ts] [$Level] $Message" -Encoding UTF8
    switch ($Level) {
        "ERROR" { Write-Host "  ❌  $Message" -ForegroundColor Red }
        "WARN"  { Write-Host "  ⚠  $Message" -ForegroundColor Yellow }
        "OK"    { Write-Host "  ✅  $Message" -ForegroundColor Green }
        default { Write-Host "  ℹ   $Message" -ForegroundColor DarkGray }
    }
}
Write-Log "TEMPLATE started" "INFO"

# ─── 2. SAFEMODE CHECK ────────────────────────────────────────
$profileCfgPath = Join-Path $env:USERPROFILE ".dev-env" "config" "profile.json"
$profileCfg = if (Test-Path $profileCfgPath) { try { Get-Content $profileCfgPath -Raw | ConvertFrom-Json } catch { $null } } else { $null }
if ($profileCfg -and $profileCfg.safeMode -and -not $Force) {
    Write-Host "  ❌  SAFE MODE ACTIVE ($($profileCfg.type)) — script blocked" -ForegroundColor Red
    Write-Host "      Use -Force to override" -ForegroundColor Yellow
    Write-Log "SafeMode blocked execution" "WARN"
    exit 1
}

# ─── 3. WHATIF ────────────────────────────────────────────────
if ($WhatIfPreference) {
    Write-Host "  [WhatIf] TEMPLATE: dry run — no changes will be made" -ForegroundColor Cyan
    Write-Log "WhatIf mode" "INFO"
}

# ─── 4. MAIN LOGIC ────────────────────────────────────────────
Write-Host "─── TEMPLATE ─────────────────────────────────────" -ForegroundColor Cyan

if ($PSCmdlet.ShouldProcess("Target", "Operation")) {
    try {
        # Your code here
        Write-Host "  ✅  Operation completed" -ForegroundColor Green
        Write-Log "Operation completed" "OK"
    } catch {
        Write-Host "  ❌  Operation failed: $_" -ForegroundColor Red
        Write-Log "Operation failed: $_" "ERROR"
        exit 1
    }
}

# ─── 5. DONE ──────────────────────────────────────────────────
Write-Log "TEMPLATE completed" "OK"
Write-Host "  📝  Log: $logFile" -ForegroundColor DarkGray
Write-Host ""
Write-Host ">>> TEMPLATE — OK" -ForegroundColor Green
exit 0
