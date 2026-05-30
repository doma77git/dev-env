#!/usr/bin/env pwsh
# === bootstrap.ps1 ============================================
# URL:    https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5
# ROLE:   Pipeline orchestrator — calls phase scripts in order:
#         00 (core check) → 30 (clone) → 10 (detect) → 20 (report)
#         → 40 (profile) → 50 (setup) → 60 (repair) → 70 (test)
# RUN:    irm <url> | iex                                      (Windows)
#         $env:DEV_ENV_WHATIF='1'; irm <url> | iex              (dry-run)
#         ./bootstrap.ps1 -WhatIf                               (dry-run local)
#         ./bootstrap.ps1 -Force                                (CI/CD)
# PARTNER: bootstrap.sh — curl -fsSL <url> | bash               (Linux/WSL)
# ==============================================================
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Force)

# ─── Dry-run from env var (irm | iex can't pass params) ────
if (-not $WhatIf) {
    $WhatIf = [bool]([Environment]::GetEnvironmentVariable('DEV_ENV_WHATIF'))
}
if ($WhatIf) {
    Write-Host ">>> DRY-RUN MODE / SUCHÝ BĚH" -ForegroundColor Magenta
}

$ErrorActionPreference = "Continue"

# When running via irm | iex, $MyInvocation.MyCommand.Path is null
# Use repo clone as fallback until clone phase updates it
$ScriptsDir = try { Split-Path -Parent $MyInvocation.MyCommand.Path -ErrorAction Stop } catch { $null }
if (-not $ScriptsDir -or $ScriptsDir -eq '.') {
    $ScriptsDir = Join-Path $env:USERPROFILE ".dev-env/repo/scripts"
}

# ─── Helper: run a phase script ────────────────────────────
function Invoke-Phase {
    param([string]$Path, [string]$Name, [switch]$Critical)
    if (-not (Test-Path $Path)) {
        Write-Host "  ⚠  Phase script not found: $Path" -ForegroundColor Yellow
        if ($Critical) {
            Write-Host ">>> $Name — FAIL (exit 1)" -ForegroundColor Red
            exit 1
        }
        return $false
    }
    Write-Host ""
    Write-Host ">>> Loading phase: $Name ..." -ForegroundColor DarkCyan
    try {
        & $Path -Force:$Force -WhatIf:$WhatIf
        return $true
    } catch {
        Write-Host "  ❌  Phase $Name failed: $_" -ForegroundColor Red
        if ($Critical) {
            Write-Host ">>> Pipeline ABORTED at $Name (exit 1)" -ForegroundColor Red
            exit 1
        }
        return $false
    }
}

# ═══════════════════════════════════════════════════════════
#  PHASE 00: CORE CHECK (critical — PS7 + git must exist)
# ═══════════════════════════════════════════════════════════
$phase00 = Join-Path $ScriptsDir "00-core-check.ps1"
if (Test-Path $phase00) {
    & $phase00 -Force:$Force
    if ($LASTEXITCODE -ne 0) {
        Write-Host ">>> Pipeline ABORTED at phase 00 (exit $LASTEXITCODE)" -ForegroundColor Red
        exit $LASTEXITCODE
    }
} else {
    # Running from gist before clone — inline minimal check
    Write-Host ""
    Write-Host ">>> PHASE 00 — CORE CHECK (inline from gist)" -ForegroundColor Cyan
    $psVer = $PSVersionTable.PSVersion.Major
    if ($psVer -lt 7) {
        Write-Host "  ❌  PowerShell $psVer detected — PS7+ required" -ForegroundColor Red
        Write-Host "      Run 00-bootstrap-fallback.ps1 first, or install manually:" -ForegroundColor Yellow
        Write-Host "      winget install Microsoft.PowerShell" -ForegroundColor Cyan
        Write-Host ">>> Pipeline ABORTED (exit 1)" -ForegroundColor Red
        exit 1
    }
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCmd) {
        Write-Host "  ❌  Git not found — cannot clone repo" -ForegroundColor Red
        Write-Host "      Install manually: winget install Git.Git" -ForegroundColor Cyan
        Write-Host ">>> Pipeline ABORTED (exit 1)" -ForegroundColor Red
        exit 1
    }
    Write-Host "  ✅  PS$psVer + git OK" -ForegroundColor Green
}

# ═══════════════════════════════════════════════════════════
#  PHASE 30: REPOSITORY CLONE (critical — before detect)
#  Clone BEFORE detect so all scripts come from fresh repo
# ═══════════════════════════════════════════════════════════
$phase30 = Join-Path $ScriptsDir "30-clone.ps1"
if (Test-Path $phase30) {
    & $phase30 -Force:$Force -WhatIf:$WhatIf
    if ($LASTEXITCODE -ne 0) {
        Write-Host ">>> Pipeline ABORTED at phase 30 (exit $LASTEXITCODE)" -ForegroundColor Red
        exit $LASTEXITCODE
    }
} else {
    # Inline clone (first run from gist)
    Write-Host ""
    Write-Host ">>> PHASE 30 — REPOSITORY CLONE (inline)" -ForegroundColor Cyan
    $RepoUrl = "https://github.com/doma77git/dev-env"
    $RepoDir = Join-Path $env:USERPROFILE ".dev-env/repo"
    # Clone/pull always runs — read-only, needed for later phase scripts
    if ((Test-Path $RepoDir) -and (Test-Path "$RepoDir\.git")) {
        git -C $RepoDir pull origin master 2>$null
        Write-Host "  ✅  Pull complete" -ForegroundColor Green
    } else {
        git clone -b master $RepoUrl $RepoDir 2>$null
        Write-Host "  ✅  Clone complete" -ForegroundColor Green
    }
    if (Test-Path "$RepoDir/scripts") {
        $ScriptsDir = "$RepoDir/scripts"
    }
}

# ═══════════════════════════════════════════════════════════
#  PHASE 10: ENVIRONMENT DETECT (from cloned repo)
# ═══════════════════════════════════════════════════════════
$phase10 = Join-Path $ScriptsDir "10-detect.ps1"
if (Test-Path $phase10) {
    . $phase10
} else {
    Write-Host "  ⚠  10-detect.ps1 not found — continuing without inventory" -ForegroundColor Yellow
}

# ═══════════════════════════════════════════════════════════
#  PHASE 20: INVENTORY REPORT (from cloned repo)
# ═══════════════════════════════════════════════════════════
$phase20 = Join-Path $ScriptsDir "20-report.ps1"
if (Test-Path $phase20) {
    . $phase20
} else {
    Write-Host "  ⚠  20-report.ps1 not found" -ForegroundColor Yellow
}

# ═══════════════════════════════════════════════════════════
#  PHASE 40: PROFILE & IDENTITY
# ═══════════════════════════════════════════════════════════
$phase40 = Join-Path $ScriptsDir "40-profile.ps1"
if (Test-Path $phase40) {
    . $phase40 -WhatIf:$WhatIf
} else {
    Write-Host "  ⚠  40-profile.ps1 not found" -ForegroundColor Yellow
}

# ═══════════════════════════════════════════════════════════
#  PHASE 50: PACKAGE SETUP (with confirm dialog)
# ═══════════════════════════════════════════════════════════
$profileName = $ProfileName
if (-not $profileName) { $profileName = "home" }

$phase50 = Join-Path $ScriptsDir "50-setup-$profileName.ps1"
if (Test-Path $phase50) {
    if ($WhatIf) {
        Write-Host ""
        Write-Host ">>> PHASE 50 — PACKAGE SETUP ($profileName) — DRY RUN" -ForegroundColor Magenta
        & $phase50 -WhatIf
    } else {
        Write-Host ""
        Write-Host ">>> PHASE 50 — PACKAGE SETUP ($profileName)" -ForegroundColor Green
        Write-Host "  Showing what would change (dry-run):" -ForegroundColor Magenta
        & $phase50 -WhatIf

        $confirmScript = Join-Path $ScriptsDir "Confirm-Action.ps1"
        if (Test-Path $confirmScript) { . $confirmScript }
        if (Get-Command Confirm-Action -ErrorAction SilentlyContinue) {
            if ($Force -or (Confirm-Action "Apply $profileName setup changes?" 10)) {
                & $phase50 -Force
            } else {
                Write-Host "  SKIPPED — run manually: ./scripts/50-setup-$profileName.ps1 -Force" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  Confirm-Action not available — run manually:" -ForegroundColor Yellow
            Write-Host "  ./scripts/50-setup-$profileName.ps1 -Force" -ForegroundColor Cyan
        }
    }
} else {
    Write-Host "  ⚠  50-setup-$profileName.ps1 not found" -ForegroundColor Yellow
}

# ═══════════════════════════════════════════════════════════
#  PHASE 60: ENVIRONMENT REPAIR (with confirm dialog)
# ═══════════════════════════════════════════════════════════
$phase60 = Join-Path $ScriptsDir "60-repair.ps1"
if (Test-Path $phase60) {
    if ($WhatIf) {
        Write-Host ""
        Write-Host ">>> PHASE 60 — ENVIRONMENT REPAIR — DRY RUN" -ForegroundColor Magenta
        & $phase60 -WhatIf
    } else {
        & $phase60 -WhatIf
        $confirmScript = Join-Path $ScriptsDir "Confirm-Action.ps1"
        if (Test-Path $confirmScript) { . $confirmScript }
        if (Get-Command Confirm-Action -ErrorAction SilentlyContinue) {
            if ($Force -or (Confirm-Action "Apply repair changes?" 10)) {
                & $phase60 -Force
            } else {
                Write-Host "  SKIPPED — run manually: ./scripts/60-repair.ps1 -Force" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  Confirm-Action not available — run manually:" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "  ⚠  60-repair.ps1 not found" -ForegroundColor Yellow
}

# ═══════════════════════════════════════════════════════════
#  PHASE 70: VALIDATION TEST
# ═══════════════════════════════════════════════════════════
$phase70 = Join-Path $ScriptsDir "70-test.ps1"
if (Test-Path $phase70) {
    Write-Host ""
    Write-Host ">>> PHASE 70 — VALIDATION TEST" -ForegroundColor Green
    & $phase70
    $testResult = $LASTEXITCODE
    if ($testResult -eq 0) {
        Write-Host ">>> 70 — validation-test PASS (exit 0)" -ForegroundColor Green
    } else {
        Write-Host ">>> 70 — validation-test FAIL (exit $testResult)" -ForegroundColor Red
    }
} else {
    Write-Host "  ⚠  70-test.ps1 not found" -ForegroundColor Yellow
}

# ═══════════════════════════════════════════════════════════
#  PIPELINE COMPLETE
# ═══════════════════════════════════════════════════════════
Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  PIPELINE COMPLETE                        ║" -ForegroundColor Green
Write-Host "║  Všechny fáze dokončeny                  ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host "  Status files: ~/.dev-env/" -ForegroundColor DarkGray
