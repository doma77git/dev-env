#!/usr/bin/env pwsh
# === scripts/00-bootstrap-fallback.ps1 =========================
# ROLE:   PS5 fallback — install pwsh + Terminal + Git, then hand off
#         Minimalní bootstrap pro Windows PowerShell 5.1
#         check→recommend→try→run pro každý missing tool
#         Když chybí winget: přímé URL ke stažení
# RUN:    irm <gist> | iex                                       (PS5)
#         irm <gist> | iex                                       (PS7 — přesměruje)
# PS5:    kompatibilní — bez ??, bez ternárního operátoru
# =====================================================================
param([switch]$WhatIf)
if ($WhatIf) { Write-Host ">>> DRY-RUN / SUCHÝ BĚH" -ForegroundColor Magenta }

$ErrorActionPreference = "Continue"

$GistUrl      = "https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5"
$BootstrapUrl = "$GistUrl/raw/bootstrap.ps1"

# ═══ DETECT — PS version ═══════════════════════════════════════
Write-Host ""
Write-Host ">>> FALLBACK BOOTSTRAP — PS5 MINIMAL SETUP" -ForegroundColor Cyan

$psVer = $PSVersionTable.PSVersion.Major
$psLabel = if ($psVer -ge 7) { "PowerShell $psVer (Core)" } else { "Windows PowerShell $psVer" }
Write-Host "  Detected: $psLabel" -ForegroundColor $(if ($psVer -ge 7) { "Green" } else { "Yellow" })

if ($psVer -ge 7) {
    Write-Host "  PowerShell 7+ already installed — running main bootstrap:" -ForegroundColor Green
    Write-Host "  irm $BootstrapUrl | iex" -ForegroundColor Cyan
    exit 0
}

Write-Host "  PS5 — checking prerequisites ..." -ForegroundColor Yellow

# ═══ CHECK — detect winget ══════════════════════════════════════
Write-Host ""
Write-Host ">>> WINGET — check" -ForegroundColor Cyan

$wingetCmd = $null
try { $wingetCmd = Get-Command winget -ErrorAction Stop } catch {}
$hasWinget = ($null -ne $wingetCmd)

if ($hasWinget) {
    Write-Host "  OK  winget found" -ForegroundColor Green
} else {
    Write-Host "  MISS winget not available" -ForegroundColor Yellow
    Write-Host "  TRY: direct install from GitHub ..." -ForegroundColor Yellow
    
    # Microsoft Desktop App Installer (includes winget)
    $wingetBundleUrl = "https://github.com/microsoft/winget-cli/releases/download/v1.9.25200/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    $wingetBundle = Join-Path $env:TEMP "DesktopAppInstaller.msixbundle"
    $vclibUrl = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
    $vclib = Join-Path $env:TEMP "VCLibs.appx"
    
    try {
        # Step 1: VCLibs dependency
        Write-Host "    Downloading VCLibs ..." -ForegroundColor DarkGray
        (New-Object Net.WebClient).DownloadFile($vclibUrl, $vclib)
        Write-Host "    Installing VCLibs ..." -ForegroundColor Yellow
        Add-AppxPackage -Path $vclib -ErrorAction SilentlyContinue
        
        # Step 2: DesktopAppInstaller (winget)
        Write-Host "    Downloading winget bundle ..." -ForegroundColor DarkGray
        (New-Object Net.WebClient).DownloadFile($wingetBundleUrl, $wingetBundle)
        Write-Host "    Installing winget ..." -ForegroundColor Yellow
        Add-AppxPackage -Path $wingetBundle -ErrorAction Stop
        
        Remove-Item $wingetBundle, $vclib -Force -ErrorAction SilentlyContinue
        Write-Host "    winget installed!" -ForegroundColor Green
        $hasWinget = $true
    } catch {
        Write-Host "    winget install failed: $_" -ForegroundColor Red
        Write-Host "  FALLBACK: manual install from Store" -ForegroundColor DarkGray
        Write-Host "    https://apps.microsoft.com/detail/9nblggh4nns1" -ForegroundColor DarkGray
    }
}

# ═══ TOOL: PowerShell 7 — check→recommend→try→run ═══════════════
Write-Host ""
Write-Host ">>> POWERSHELL 7" -ForegroundColor Cyan

# CHECK
$pwshCmd = $null
try { $pwshCmd = Get-Command pwsh -ErrorAction Stop } catch {}
$hasPwsh = ($null -ne $pwshCmd)

if ($hasPwsh) {
    Write-Host "  OK  pwsh $($pwshCmd.Version)" -ForegroundColor Green
} else {
    Write-Host "  MISS PowerShell 7 not installed" -ForegroundColor Yellow

    # RECOMMEND
    if ($hasWinget) {
        Write-Host "  RECOMMEND: winget install Microsoft.PowerShell" -ForegroundColor DarkGray
    } else {
        Write-Host "  RECOMMEND: download from GitHub releases" -ForegroundColor DarkGray
    }

    # TRY — winget preferred, else direct MSI
    if ($WhatIf) {
        if ($hasWinget) {
            Write-Host "  [WHATIF] Would: winget install --id Microsoft.PowerShell" -ForegroundColor DarkCyan
        } else {
            Write-Host "  [WHATIF] Would: download MSI from GitHub" -ForegroundColor DarkCyan
        }
    } elseif ($hasWinget) {
        Write-Host "  TRY: winget install --id Microsoft.PowerShell ..." -ForegroundColor Yellow
        try {
            winget install --id Microsoft.PowerShell --accept-source-agreements --silent 2>&1 | Out-Null
            Write-Host "  Installed" -ForegroundColor Green
        } catch {
            Write-Host "  FAIL: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  TRY: direct download from GitHub ..." -ForegroundColor Yellow
        $pwshMsiUrl = "https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-x64.msi"
        $pwshMsi = Join-Path $env:TEMP "PowerShell-7.4.6-win-x64.msi"
        try {
            Write-Host "    Downloading $pwshMsiUrl ..." -ForegroundColor DarkGray
            (New-Object Net.WebClient).DownloadFile($pwshMsiUrl, $pwshMsi)
            Write-Host "    Installing via msiexec ..." -ForegroundColor Yellow
            Start-Process msiexec.exe -ArgumentList "/i `"$pwshMsi`" /quiet /norestart ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ADD_FILE_CONTEXT_MENU_RUN_POWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1" -Wait
            Remove-Item $pwshMsi -Force -ErrorAction SilentlyContinue
            Write-Host "    pwsh installed" -ForegroundColor Green
        } catch {
            Write-Host "    Direct download failed: $_" -ForegroundColor Red
        }
    }
}

# RUN — verify (check PATH + direct paths)
$pwshPaths = @(
    "$env:ProgramFiles\PowerShell\7\pwsh.exe",
    "${env:ProgramFiles(x86)}\PowerShell\7\pwsh.exe",
    "$env:LOCALAPPDATA\Microsoft\WindowsApps\pwsh.exe"
)
$pwshFound = $null
# Refresh PATH from registry after MSI install
try {
    $regPath = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    $newPath = (Get-ItemProperty -Path $regPath -Name PATH -ErrorAction SilentlyContinue).PATH
    if ($newPath) { $env:PATH = "$env:PATH;$newPath" }
} catch {}
# Try Get-Command first
$pwshCmd2 = $null
try { $pwshCmd2 = Get-Command pwsh -ErrorAction Stop } catch {}
if ($null -ne $pwshCmd2) {
    $pwshFound = $pwshCmd2.Source
    Write-Host "  RUN: pwsh verified OK ($pwshFound)" -ForegroundColor Green
} else {
    # Try direct paths
    foreach ($p in $pwshPaths) {
        if (Test-Path $p) { $pwshFound = $p; break }
    }
    if ($pwshFound) {
        Write-Host "  RUN: pwsh found at $pwshFound" -ForegroundColor Green
        # Add to PATH for this session
        $pwshDir = Split-Path $pwshFound -Parent
        $env:PATH = "$pwshDir;$env:PATH"
    } else {
        Write-Host "  RUN: pwsh not found — may need reboot" -ForegroundColor Yellow
    }
}

# ═══ TOOL: Windows Terminal — check→recommend→try→run ═══════════
Write-Host ""
Write-Host ">>> WINDOWS TERMINAL" -ForegroundColor Cyan

# CHECK
$wtCmd = $null
try { $wtCmd = Get-Command wt -ErrorAction Stop } catch {}
$hasWt = ($null -ne $wtCmd)

if ($hasWt) {
    Write-Host "  OK  Windows Terminal available" -ForegroundColor Green
} else {
    Write-Host "  MISS Windows Terminal not installed" -ForegroundColor Yellow

    # RECOMMEND
    if ($hasWinget) {
        Write-Host "  RECOMMEND: winget install Microsoft.WindowsTerminal" -ForegroundColor DarkGray
    } else {
        Write-Host "  RECOMMEND: https://apps.microsoft.com/detail/9n0dx20hk701" -ForegroundColor DarkGray
    }

    # TRY — winget only for now (WT has no simple offline installer)
    if ($hasWinget -and -not $WhatIf) {
        Write-Host "  TRY: winget install --id Microsoft.WindowsTerminal ..." -ForegroundColor Yellow
        try {
            winget install --id Microsoft.WindowsTerminal --accept-source-agreements --silent 2>&1 | Out-Null
            Write-Host "  Installed" -ForegroundColor Green
        } catch {
            Write-Host "  FAIL: $_" -ForegroundColor Red
        }
    } elseif ($WhatIf) {
        Write-Host "  [WHATIF] Would: winget install --id Microsoft.WindowsTerminal" -ForegroundColor DarkCyan
    } else {
        Write-Host "  SKIP: no winget, install manually from URL above" -ForegroundColor Yellow
    }
}

# RUN — verify
$wtCmd2 = $null
try { $wtCmd2 = Get-Command wt -ErrorAction Stop } catch {}
if ($null -ne $wtCmd2) {
    Write-Host "  RUN: wt verified OK" -ForegroundColor Green
} else {
    Write-Host "  RUN: wt not yet available — may need PATH refresh" -ForegroundColor Yellow
}

# ═══ TOOL: Git — check→recommend→try→run ════════════════════════
Write-Host ""
Write-Host ">>> GIT" -ForegroundColor Cyan

# CHECK
$gitCmd = $null
try { $gitCmd = Get-Command git -ErrorAction Stop } catch {}
$hasGit = ($null -ne $gitCmd)

if ($hasGit) {
    Write-Host "  OK  git $(& git --version 2>&1 | Select-Object -First 1)" -ForegroundColor Green
} else {
    Write-Host "  MISS Git not installed" -ForegroundColor Yellow

    # RECOMMEND
    if ($hasWinget) {
        Write-Host "  RECOMMEND: winget install Git.Git" -ForegroundColor DarkGray
    } else {
        Write-Host "  RECOMMEND: download from git-scm.com" -ForegroundColor DarkGray
    }

    # TRY — winget preferred, else direct download
    if ($WhatIf) {
        if ($hasWinget) {
            Write-Host "  [WHATIF] Would: winget install --id Git.Git" -ForegroundColor DarkCyan
        } else {
            Write-Host "  [WHATIF] Would: download Git installer" -ForegroundColor DarkCyan
        }
    } elseif ($hasWinget) {
        Write-Host "  TRY: winget install --id Git.Git ..." -ForegroundColor Yellow
        try {
            winget install --id Git.Git --accept-source-agreements --silent 2>&1 | Out-Null
            Write-Host "  Installed — restart terminal or refresh PATH" -ForegroundColor Green
        } catch {
            Write-Host "  FAIL: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  TRY: direct download from GitHub ..." -ForegroundColor Yellow
        $gitExeUrl = "https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.2/Git-2.47.1.2-64-bit.exe"
        $gitExe = Join-Path $env:TEMP "Git-2.47.1.2-64-bit.exe"
        try {
            Write-Host "    Downloading $gitExeUrl ..." -ForegroundColor DarkGray
            (New-Object Net.WebClient).DownloadFile($gitExeUrl, $gitExe)
            Write-Host "    Installing Git (silent) ..." -ForegroundColor Yellow
            Start-Process $gitExe -ArgumentList "/VERYSILENT /NORESTART /NOCANCEL /SP- /NOICONS /COMPONENTS=icons,ext,ext\reg,assoc,assoc_sh" -Wait
            Remove-Item $gitExe -Force -ErrorAction SilentlyContinue
            Write-Host "    Git installed" -ForegroundColor Green
        } catch {
            Write-Host "    Direct download failed: $_" -ForegroundColor Red
        }
    }
}

# RUN — verify (check PATH + direct paths)
$gitPaths = @(
    "${env:ProgramFiles}\Git\bin\git.exe",
    "${env:ProgramFiles(x86)}\Git\bin\git.exe"
)
$gitCmd2 = $null
try { $gitCmd2 = Get-Command git -ErrorAction Stop } catch {}
if ($null -ne $gitCmd2) {
    Write-Host "  RUN: git verified OK" -ForegroundColor Green
} else {
    # Try direct paths
    $gitFound = $null
    foreach ($p in $gitPaths) { if (Test-Path $p) { $gitFound = $p; break } }
    if ($gitFound) {
        Write-Host "  RUN: git found at $gitFound" -ForegroundColor Green
        $env:PATH = "$(Split-Path $gitFound -Parent);$env:PATH"
    } else {
        Write-Host "  RUN: git not found" -ForegroundColor Yellow
    }
}

# ═══ HAND OFF ═══════════════════════════════════════════════════
Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  FALLBACK COMPLETE                       ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Green

# Final check (use $pwshFound from earlier if available)
$pwshFinal = if ($pwshFound) { $pwshFound } else { $null; try { (Get-Command pwsh -ErrorAction Stop).Source } catch { $null } }
$missing = @()
if ($null -eq $pwshFinal) { $missing += "PowerShell 7" }
$wtFinal = $null; try { $wtFinal = Get-Command wt -ErrorAction Stop } catch {}
if ($null -eq $wtFinal) { $missing += "Windows Terminal" }
$gitFinal = $null; try { $gitFinal = Get-Command git -ErrorAction Stop } catch {}
if ($null -eq $gitFinal) { $missing += "Git" }

# Launch pwsh in a new window (gets fresh PATH from MSI install)
$pwshExe = if ($pwshFound -and (Test-Path $pwshFound)) { $pwshFound } else { "pwsh" }
$tempScript = Join-Path $env:TEMP "dev-env-bootstrap.ps1"
@"
Write-Host ">>> Starting main bootstrap in fresh PowerShell 7 window..." -ForegroundColor Cyan
Write-Host ""
if (`$WhatIf) { `$env:DEV_ENV_WHATIF = '1' }
irm $BootstrapUrl | iex
Write-Host ""
Write-Host "=== Pipeline complete ===" -ForegroundColor Green
Write-Host "Press Enter to close this window..." -ForegroundColor Cyan
`$null = Read-Host
"@ | Set-Content $tempScript -Encoding UTF8

if ($missing.Count -eq 0) {
    Write-Host ""
    Write-Host "  All prerequisites ready!" -ForegroundColor Green
    Write-Host "  Spawning new pwsh window with main bootstrap ..." -ForegroundColor Cyan
    Write-Host "  (new window gets fresh PATH from install)" -ForegroundColor DarkGray
    Start-Process -FilePath $pwshExe -ArgumentList "-NoProfile -NoLogo -File `"$tempScript`"" -WindowStyle Normal
} elseif ($null -ne $pwshFound) {
    Write-Host ""
    Write-Host "  pwsh is ready! Spawning new window with main bootstrap ..." -ForegroundColor Cyan
    Start-Process -FilePath $pwshExe -ArgumentList "-NoProfile -NoLogo -File `"$tempScript`"" -WindowStyle Normal
} else {
    Write-Host ""
    Write-Host "  Still missing: $($missing -join ', ')" -ForegroundColor Yellow
    if ($null -eq $pwshFound) {
        Write-Host "  PowerShell 7 is critical — install it first" -ForegroundColor Red
    }
    Write-Host "  Then run:" -ForegroundColor Yellow
    Write-Host "    pwsh -NoProfile -Command `"irm $BootstrapUrl | iex`"" -ForegroundColor White
}
Write-Host ""
