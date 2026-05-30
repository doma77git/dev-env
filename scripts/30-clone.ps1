#!/usr/bin/env pwsh
# === scripts/30-clone.ps1 =====================================
# ROLE:   Git clone or pull ~/.dev-env/repo/
#         Klonování / aktualizace repa
# RULE:   DETECT → if no git → REPORT → RECOMMEND → EXIT
#         Never installs git automatically
# RUN:    ./30-clone.ps1               (interactive — dotaz před pull)
#         ./30-clone.ps1 -Force         (CI/CD — pull bez dotazu)
#         ./30-clone.ps1 -WhatIf        (suchý běh)
# ==============================================================
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Force)

$ErrorActionPreference = "Continue"
$RepoUrl = "https://github.com/doma77git/dev-env"
$RepoDir = Join-Path $env:USERPROFILE ".dev-env/repo"

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  PHASE 30 — REPOSITORY CLONE             ║" -ForegroundColor Cyan
Write-Host "║  Klonování / aktualizace repa            ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan

# ─── Check git ─────────────────────────────────────────────
$gitCmd = Get-Command git -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $gitCmd) {
    Write-Host "  ❌  Git not found — cannot clone" -ForegroundColor Red
    Write-Host "      Recommend: winget install Git.Git" -ForegroundColor Cyan
    Write-Host "      Download:  https://git-scm.com/downloads" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host ">>> 30 — repository-clone FAIL (exit 1)" -ForegroundColor Red
    exit 1
}

# ─── Clone or pull (always runs — read-only, not a mutation)
#      Clone/pull always executes even in dry-run mode because
#      later phases (detect/report) need scripts from the repo.
Write-Host ""

if ((Test-Path $RepoDir) -and (Test-Path "$RepoDir\.git")) {
    # Existing repo — pull
    Write-Host "  Repo exists — pulling latest ..." -ForegroundColor Yellow
    try {
        git -C $RepoDir fetch origin
        git -C $RepoDir checkout master 2>$null
        git -C $RepoDir pull origin master
        # Fix tracking if misconfigured
        $upstream = git -C $RepoDir rev-parse --abbrev-ref '@{upstream}' 2>$null
        if ($upstream -notmatch 'origin/master') {
            git -C $RepoDir branch --set-upstream-to=origin/master master 2>$null
        }
        Write-Host "  ✅  Pull complete" -ForegroundColor Green
    } catch {
        Write-Host "  ❌  Pull failed: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host ">>> 30 — repository-clone FAIL (exit 1)" -ForegroundColor Red
        exit 1
    }
} elseif (Test-Path $RepoDir) {
    # Broken repo directory — remove and reclone
    Write-Host "  ⚠  Broken repo — removing and re-cloning ..." -ForegroundColor Yellow
    try {
        Remove-Item $RepoDir -Recurse -Force -ErrorAction SilentlyContinue
        git clone -b master $RepoUrl $RepoDir
        Write-Host "  ✅  Clone complete" -ForegroundColor Green
    } catch {
        Write-Host "  ❌  Clone failed: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host ">>> 30 — repository-clone FAIL (exit 1)" -ForegroundColor Red
        exit 1
    }
} else {
    # Fresh clone
    Write-Host "  git clone -b master $RepoUrl $RepoDir" -ForegroundColor Yellow
    try {
        git clone -b master $RepoUrl $RepoDir
        Write-Host "  ✅  Clone complete" -ForegroundColor Green
    } catch {
        Write-Host "  ❌  Clone failed: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host ">>> 30 — repository-clone FAIL (exit 1)" -ForegroundColor Red
        exit 1
    }
}

Write-Host "  Repo: $RepoDir" -ForegroundColor Green
Write-Host ""
Write-Host ">>> 30 — repository-clone OK" -ForegroundColor Green
