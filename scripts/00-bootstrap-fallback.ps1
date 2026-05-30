#!/usr/bin/env pwsh
# === scripts/00-bootstrap-fallback.ps1 ========================
# ROLE:   PS5 fallback — DETECT → REPORT → RECOMMEND → EXIT
#         Nikdy nic neinstaluje automaticky!
#         Pouze detekuje chybějící závislosti a doporučí postup.
# RUN:    ./00-bootstrap-fallback.ps1     (detekce + doporučení)
#         ./00-bootstrap-fallback.ps1 -Force  (CI/CD — stejné chování)
# ==============================================================
[CmdletBinding(SupportsShouldProcess=$false)]
param([switch]$Force)

$ErrorActionPreference = "Continue"
$GistUrl      = "https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5"
$BootstrapUrl = "$GistUrl/raw/bootstrap.ps1"

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  FALLBACK BOOTSTRAP — PS5 MINIMAL SETUP  ║" -ForegroundColor Cyan
Write-Host "║  Detekce → Report → Doporučení → Exit    ║" -ForegroundColor Cyan
Write-Host "║  Nikdy neinstaluje automaticky           ║" -ForegroundColor White
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan

$psVer = $PSVersionTable.PSVersion.Major
$psLabel = if ($psVer -ge 7) { "PowerShell $psVer (Core)" } else { "Windows PowerShell $psVer" }
Write-Host "  Detected: $psLabel" -ForegroundColor $(if ($psVer -ge 7) { "Green" } else { "Yellow" })

# ─── If PS7+ — hand off to main bootstrap ─────────────────
if ($psVer -ge 7) {
    Write-Host ""
    Write-Host "  ✅  PowerShell 7+ already installed — no fallback needed." -ForegroundColor Green
    Write-Host "      Run main bootstrap:" -ForegroundColor Cyan
    Write-Host "      irm $BootstrapUrl | iex" -ForegroundColor White
    Write-Host ""
    Write-Host ">>> FALLBACK — no action needed (exit 0)" -ForegroundColor Green
    exit 0
}

# ─── PS5 — check prerequisites ────────────────────────────
Write-Host ""
Write-Host "  ⚠  Windows PowerShell $psVer detected — pipeline requires PS7+" -ForegroundColor Yellow
Write-Host ""

$missing = @()

# 1. PowerShell 7
$pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue | Select-Object -First 1
if ($pwshCmd) {
    $pwshVer = try { (& pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>$null) } catch { "?" }
    Write-Host "  ✅  pwsh: $pwshVer at $($pwshCmd.Source)" -ForegroundColor Green
} else {
    Write-Host "  ❌  pwsh: NOT INSTALLED" -ForegroundColor Red
    $missing += "PowerShell 7"
}

# 2. Windows Terminal
$wtCmd = Get-Command wt -ErrorAction SilentlyContinue | Select-Object -First 1
if ($wtCmd) {
    Write-Host "  ✅  Windows Terminal: available at $($wtCmd.Source)" -ForegroundColor Green
} else {
    Write-Host "  ❌  Windows Terminal: NOT INSTALLED" -ForegroundColor Yellow
    $missing += "Windows Terminal"
}

# 3. Git
$gitCmd = Get-Command git -ErrorAction SilentlyContinue | Select-Object -First 1
if ($gitCmd) {
    $gitVer = try { (& git --version 2>&1 | Select-Object -First 1) -join '' } catch { "?" }
    Write-Host "  ✅  git: $gitVer" -ForegroundColor Green
} else {
    Write-Host "  ❌  git: NOT INSTALLED" -ForegroundColor Red
    $missing += "Git"
}

# ─── Summary ──────────────────────────────────────────────
Write-Host ""
Write-Host "─── SUMMARY ──────────────────────────────────" -ForegroundColor Cyan

if ($missing.Count -eq 0) {
    Write-Host "  ✅  All prerequisites met!" -ForegroundColor Green
    Write-Host "      Run main bootstrap in a new pwsh window:" -ForegroundColor Cyan
    Write-Host "      start pwsh -NoProfile -Command `"irm $BootstrapUrl | iex`"" -ForegroundColor White
    Write-Host ">>> FALLBACK — all OK (exit 0)" -ForegroundColor Green
    exit 0
}

Write-Host "  ❌  Missing dependencies: $($missing -join ', ')" -ForegroundColor Red
Write-Host ""
Write-Host "  ── INSTALLATION GUIDE ──────────────────────" -ForegroundColor Cyan

foreach ($m in $missing) {
    switch ($m) {
        "PowerShell 7" {
            Write-Host "  $m :" -ForegroundColor Yellow
            Write-Host "      winget install Microsoft.PowerShell" -ForegroundColor White
            Write-Host "      or download: https://github.com/PowerShell/PowerShell/releases" -ForegroundColor DarkGray
        }
        "Windows Terminal" {
            Write-Host "  $m :" -ForegroundColor Yellow
            Write-Host "      winget install Microsoft.WindowsTerminal" -ForegroundColor White
            Write-Host "      or from Store: https://apps.microsoft.com/detail/9n0dx20hk701" -ForegroundColor DarkGray
        }
        "Git" {
            Write-Host "  $m :" -ForegroundColor Yellow
            Write-Host "      winget install Git.Git" -ForegroundColor White
            Write-Host "      or download: https://git-scm.com/downloads" -ForegroundColor DarkGray
        }
        default {
            Write-Host "  $m : install manually" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "  Then re-run this fallback or run main bootstrap directly:" -ForegroundColor Cyan
Write-Host "      pwsh -NoProfile -Command `"irm $BootstrapUrl | iex`"" -ForegroundColor White
Write-Host ""
Write-Host ">>> FALLBACK — missing dependencies (exit 1)" -ForegroundColor Red
exit 1
