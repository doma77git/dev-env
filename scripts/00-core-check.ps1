#!/usr/bin/env pwsh
# === scripts/00-core-check.ps1 ================================
# ROLE:   Prerequisites check — PS version, git, connectivity
#         Detekce závislostí — nikdy nic neinstaluje
# RULE:   DETECT → REPORT → RECOMMEND → EXIT (if critical missing)
#         Never installs anything automatically
# RUN:    ./00-core-check.ps1          (interactive)
#         ./00-core-check.ps1 -Force   (CI/CD — reportuje, neptá se, exit 1 při chybě)
# ==============================================================
[CmdletBinding(SupportsShouldProcess=$false)]
param([switch]$Force)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  PHASE 00 — CORE CHECK                   ║" -ForegroundColor Cyan
Write-Host "║  Detekce závislostí / Prerequisites       ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan

$criticalFails = @()
$warnings = @()

# ─── 1. PowerShell version ─────────────────────────────────
Write-Host ""
Write-Host "00.1 PowerShell version" -ForegroundColor Cyan

$psVer = $PSVersionTable.PSVersion.Major
$psLabel = if ($psVer -ge 7) { "PowerShell $($PSVersionTable.PSVersion) (Core)" } else { "Windows PowerShell $psVer" }

if ($psVer -ge 7) {
    Write-Host "  ✅  $psLabel" -ForegroundColor Green
} else {
    Write-Host "  ❌  $psLabel" -ForegroundColor Red
    Write-Host "      This pipeline requires PowerShell 7+." -ForegroundColor Yellow
    Write-Host "      Recommend: winget install Microsoft.PowerShell" -ForegroundColor Cyan
    Write-Host "      Download:  https://github.com/PowerShell/PowerShell/releases" -ForegroundColor DarkGray
    $criticalFails += "PowerShell 7+ required (detected: $psLabel)"
}

# ─── 2. Git ────────────────────────────────────────────────
Write-Host ""
Write-Host "00.2 Git" -ForegroundColor Cyan

$gitCmd = Get-Command git -ErrorAction SilentlyContinue | Select-Object -First 1

if ($gitCmd) {
    $gitVer = try { (& git --version 2>&1 | Select-Object -First 1) -join '' } catch { "?" }
    Write-Host "  ✅  Git: $gitVer" -ForegroundColor Green
    Write-Host "      $($gitCmd.Source)" -ForegroundColor DarkGray
} else {
    Write-Host "  ❌  Git not found / nenalezen" -ForegroundColor Red
    Write-Host "      Recommend: winget install Git.Git" -ForegroundColor Cyan
    Write-Host "      Download:  https://git-scm.com/downloads" -ForegroundColor DarkGray
    $criticalFails += "Git not found — clone phase requires it"
}

# ─── 3. Connectivity (optional — warn only) ────────────────
Write-Host ""
Write-Host "00.3 Network connectivity" -ForegroundColor Cyan

try {
    $ping = Test-Connection "github.com" -Count 1 -Quiet -ErrorAction SilentlyContinue
    if ($ping) {
        Write-Host "  ✅  github.com reachable" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  github.com unreachable (offline?)" -ForegroundColor Yellow
        Write-Host "      Clone/setup will be skipped until connectivity restored" -ForegroundColor DarkGray
        $warnings += "github.com unreachable — offline mode"
    }
} catch {
    Write-Host "  ⚠️  Connectivity check failed: $_" -ForegroundColor Yellow
    $warnings += "Connectivity check error: $_"
}

# ─── 4. Summary ────────────────────────────────────────────
Write-Host ""
Write-Host "─── CORE CHECK SUMMARY ────────────────────────" -ForegroundColor Cyan

if ($criticalFails.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "  ✅  All prerequisites OK" -ForegroundColor Green
    Write-Host ">>> 00 — core-check PASS (exit 0)" -ForegroundColor Green
    exit 0
}

if ($criticalFails.Count -gt 0) {
    Write-Host "  ❌  Critical issues ($($criticalFails.Count)):" -ForegroundColor Red
    foreach ($f in $criticalFails) {
        Write-Host "      - $f" -ForegroundColor Red
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "  ⚠️  Warnings ($($warnings.Count)):" -ForegroundColor Yellow
    foreach ($w in $warnings) {
        Write-Host "      - $w" -ForegroundColor Yellow
    }
}

# ─── 5. Exit — critical failures always exit 1 ─────────────
if ($criticalFails.Count -gt 0) {
    Write-Host ""
    Write-Host "  Install missing dependencies manually, then re-run." -ForegroundColor Cyan
    Write-Host "  Or use: scripts/00-bootstrap-fallback.ps1" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host ">>> 00 — core-check FAIL (exit 1)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host ">>> 00 — core-check PASS with warnings (exit 0)" -ForegroundColor Green
exit 0
