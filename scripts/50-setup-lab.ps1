#!/usr/bin/env pwsh
# === scripts/50-setup-lab.ps1 =================================
# ROLE:   Lab VM setup — scoop, WSL, experimental tools
#         Instalace testovací VM
# RUN:    ./50-setup-lab.ps1 -WhatIf     (dry run / suchý běh)
#         ./50-setup-lab.ps1 -Force        (apply / aplikovat)
# ==============================================================
param([switch]$Force, [switch]$WhatIf)

$profile = Get-Content (Join-Path $PSScriptRoot ".." "profiles" "lab.json") -Raw | ConvertFrom-Json

Write-Host ">>> PHASE 50 — PACKAGE SETUP (lab) / INSTALACE VM" -ForegroundColor Green
Write-Host ""

# 1. WSL enable
Write-Host "5.1 WSL / Windows Subsystem for Linux" -ForegroundColor Cyan
$wslInstalled = $false
try {
    $wslStatus = wsl --status 2>&1 | Select-String "Default Version"
    $wslInstalled = $wslStatus -ne $null
} catch {}
if ($wslInstalled) {
    Write-Host "  OK  WSL is installed / nainstalováno" -ForegroundColor Green
} else {
    Write-Host "  MISS WSL not installed / není nainstalováno" -ForegroundColor Yellow
    if ($Force) {
        Write-Host "  Enabling WSL feature ..." -ForegroundColor DarkCyan
        try {
            dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /quiet /norestart | Out-Null
            dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /quiet /norestart | Out-Null
            Write-Host "  WSL enabled — reboot may be required / restart může být nutný" -ForegroundColor Yellow
            wsl --set-default-version 2
            Write-Host "  WSL 2 set as default" -ForegroundColor DarkCyan
        } catch {
            Write-Host "  FAIL: $_ — try manually: dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all" -ForegroundColor Red
        }
    }
    if ($WhatIf) {
        Write-Host "  [WHATIF] Would enable WSL + VirtualMachinePlatform features" -ForegroundColor DarkCyan
        Write-Host "  [WHATIF] Would set WSL 2 as default" -ForegroundColor DarkCyan
    }
}

# 2. Scoop installation
Write-Host "5.2 Scoop / package manager" -ForegroundColor Cyan
$scoopInstalled = Get-Command scoop -ErrorAction SilentlyContinue
if ($scoopInstalled) {
    Write-Host "  OK  Scoop installed / nainstalováno" -ForegroundColor Green
} else {
    Write-Host "  MISS Scoop not installed / není nainstalováno" -ForegroundColor Yellow
    if ($Force) {
        Write-Host "  Installing Scoop ..." -ForegroundColor DarkCyan
        try {
            Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
            irm get.scoop.sh | iex
            Write-Host "  Scoop installed" -ForegroundColor DarkCyan
        } catch {
            Write-Host "  FAIL: $_ — try: irm get.scoop.sh | iex" -ForegroundColor Red
        }
    }
    if ($WhatIf) {
        Write-Host "  [WHATIF] Would install Scoop via irm get.scoop.sh | iex" -ForegroundColor DarkCyan
    }
}

# 3. Scoop packages
Write-Host "5.3 Packages / balíčky (scoop)" -ForegroundColor Cyan
$scoopPackages = @(
    "git",
    "nodejs-lts",
    "python",
    "vscode",
    "gh",
    "curl",
    "7zip",
    "neovim",
    "docker",
    "nvm",
    "starship",
    "yarn",
    "htop",
    "jq",
    "ripgrep",
    "fd"
)
$scoopCmd = Get-Command scoop -ErrorAction SilentlyContinue
foreach ($pkg in $scoopPackages) {
    if ($scoopCmd) {
        $installed = scoop list 2>$null | Select-String -SimpleMatch $pkg
    } else {
        $installed = $null
    }
    if ($installed) {
        Write-Host "  OK  $pkg" -ForegroundColor Green
    } else {
        Write-Host "  MISS $pkg" -ForegroundColor Yellow
        if ($Force -and $scoopCmd)  { Write-Host "  Installing $pkg ..."; scoop install $pkg }
        if ($WhatIf) { Write-Host "  [WHATIF] Would scoop install $pkg" -ForegroundColor DarkCyan }
    }
}

# 4. Docker
Write-Host "5.4 Docker / kontejnery" -ForegroundColor Cyan
$dockerInstalled = Get-Command docker -ErrorAction SilentlyContinue
if ($dockerInstalled) {
    Write-Host "  OK  Docker installed / nainstalováno" -ForegroundColor Green
    $dockerRunning = docker info 2>&1 | Select-String "Server Version"
    if ($dockerRunning) {
        Write-Host "  OK  Docker daemon running / běží" -ForegroundColor Green
    } else {
        Write-Host "  ⚠  Docker installed but not running / nainstalováno ale neběží" -ForegroundColor Yellow
        if ($WhatIf) { Write-Host "  [WHATIF] Would start Docker Desktop" -ForegroundColor DarkCyan }
    }
} else {
    Write-Host "  MISS Docker not installed / není nainstalováno" -ForegroundColor Yellow
    Write-Host "       Install via: scoop install docker  or  winget install Docker.DockerDesktop" -ForegroundColor DarkGray
    if ($WhatIf) { Write-Host "  [WHATIF] Would install Docker" -ForegroundColor DarkCyan }
}

# 5. Directories / složky (lab paths)
Write-Host "5.5 Directories / složky" -ForegroundColor Cyan
$dirs = @(
    "~\dev\projects\osobni",
    "~\dev\projects\lab",
    "~\.config\powershell",
    "~\bin",
    "~\.dev-env\config",
    "~\Documents\downloads\_temp",
    "~\Documents\downloads\keep",
    "~\Documents\chat-exports"
)
foreach ($d in $dirs) {
    $expanded = [Environment]::ExpandEnvironmentVariables($d.Replace("~", $env:USERPROFILE))
    if (Test-Path $expanded) {
        Write-Host "  OK  $d" -ForegroundColor Green
    } else {
        Write-Host "  NEW $d" -ForegroundColor Yellow
        if ($Force)   { New-Item -ItemType Directory -Path $expanded -Force | Out-Null; Write-Host "  Created" -ForegroundColor DarkCyan }
        if ($WhatIf)  { Write-Host "  [WHATIF] Would create $d" -ForegroundColor DarkCyan }
    }
}

# 6. Symlink configs
Write-Host "5.6 Config symlinks / symlinky" -ForegroundColor Cyan
& "$PSScriptRoot\link-configs.ps1" -WhatIf:$WhatIf -Force:$Force

Write-Host ""
Write-Host ""
Write-Host ">>> 50 — package-setup (lab) OK" -ForegroundColor Green
if ($Force)   { Write-Host "  packages installed, proceeding with phase 60" -ForegroundColor DarkGray }
if ($WhatIf)  { Write-Host "  dry-run complete, review above then run with -Force" -ForegroundColor DarkGray }
if (-not $Force -and -not $WhatIf) { Write-Host "  review above then run with -WhatIf or -Force" -ForegroundColor DarkGray }
Write-Host "=== DONE / HOTOVO ===" -ForegroundColor Green
if (-not $Force -and -not $WhatIf) {
    Write-Host "  Run with -WhatIf or -Force / Spust s -WhatIf nebo -Force" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  🧪  LAB NOTES:" -ForegroundColor Yellow
    Write-Host "  • Scoop installs to ~/scoop/ by default — no admin needed" -ForegroundColor Yellow
    Write-Host "  • WSL may require reboot after first enable" -ForegroundColor Yellow
    Write-Host "  • Docker Desktop requires virtualization enabled in BIOS" -ForegroundColor Yellow
    Write-Host "  • Experimental tools: htop, jq, ripgrep, fd, yarn" -ForegroundColor Yellow
}
