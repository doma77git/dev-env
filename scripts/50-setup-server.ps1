#!/usr/bin/env pwsh
# === scripts/50-setup-server.ps1 ==============================
# ROLE:   Server setup — minimal headless packages (ShouldProcess)
#         Instalace na server — minimální balíčky bez GUI
# RUN:    ./scripts/50-setup-server.ps1 [-WhatIf|-Force|-Confirm]
# ==============================================================
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Force)

$profile = if (Test-Path (Join-Path $PSScriptRoot ".." "profiles" "server.json")) {
    Get-Content (Join-Path $PSScriptRoot ".." "profiles" "server.json") -Raw | ConvertFrom-Json
} else {
    Write-Host "  ⚠  server.json not found — using base profile" -ForegroundColor Yellow
    Get-Content (Join-Path $PSScriptRoot ".." "profiles" "base.json") -Raw | ConvertFrom-Json
}

Write-Host ">>> PHASE 50 — SERVER SETUP (headless, safe mode)" -ForegroundColor DarkCyan
Write-Host "  Profile: 🖳  SERVER — minimal, no GUI tools" -ForegroundColor DarkCyan
Write-Host ""

# 5.1 HOME variable
Write-Host "  5.1 HOME" -ForegroundColor Cyan
$currentHome = [Environment]::GetEnvironmentVariable("HOME", "User")
if ($currentHome -ne $env:USERPROFILE) {
    if ($PSCmdlet.ShouldProcess("$env:USERPROFILE", "Set HOME environment variable")) {
        [Environment]::SetEnvironmentVariable("HOME", $env:USERPROFILE, "User")
        Write-Host "  Set HOME = $env:USERPROFILE" -ForegroundColor Green
    }
} else {
    Write-Host "  HOME = $currentHome (OK)" -ForegroundColor Green
}

# 5.2 Directories — minimal set for server
Write-Host ""
Write-Host "  5.2 DIRS" -ForegroundColor Cyan
$dirs = @(
    "$env:USERPROFILE\.ssh",
    "$env:USERPROFILE\.config",
    "$env:USERPROFILE\bin"
)
foreach ($d in $dirs) {
    $expanded = [Environment]::ExpandEnvironmentVariables($d)
    if (Test-Path $expanded) {
        Write-Host "  $d (OK)" -ForegroundColor Green
    } else {
        if ($PSCmdlet.ShouldProcess($d, "Create directory")) {
            New-Item -ItemType Directory -Path $expanded -Force | Out-Null
            Write-Host "  $d → created" -ForegroundColor Green
        }
    }
}

# 5.3 Packages — server minimal toolchain (no winget assumption)
Write-Host ""
Write-Host "  5.3 PACKAGES (server minimal)" -ForegroundColor Cyan

$serverTools = @(
    @{id="Git.Git"; name="Git"; reason="Version control"},
    @{id="Microsoft.PowerShell"; name="PowerShell 7"; reason="Shell"},
    @{id="Microsoft.OpenSSH.Beta"; name="OpenSSH Server"; reason="Remote access"}
)

$hasWinget = $null -ne (Get-Command winget -ErrorAction SilentlyContinue)

foreach ($tool in $serverTools) {
    $cmd = Get-Command $tool.name -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host "  ✅  $($tool.name) — $($tool.reason)" -ForegroundColor Green
    } else {
        Write-Host "  ⚠   $($tool.name) MISSING — $($tool.reason)" -ForegroundColor Yellow
        if ($hasWinget -and ($Force -or $PSCmdlet.ShouldProcess($tool.id, "winget install"))) {
            Write-Host "    Installing $($tool.id) ..." -ForegroundColor Yellow
            winget install --id $tool.id --accept-source-agreements 2>&1 | Out-Null
            if (Get-Command $tool.name -ErrorAction SilentlyContinue) {
                Write-Host "    ✅  Installed" -ForegroundColor Green
            } else {
                Write-Host "    ❌  Install may have failed" -ForegroundColor Red
            }
        } elseif (-not $hasWinget) {
            Write-Host "    ℹ  winget not available — install manually" -ForegroundColor DarkGray
        }
    }
}

# 5.4 Git identity
Write-Host ""
Write-Host "  5.4 GIT IDENTITY" -ForegroundColor Cyan
$gitName  = try { git config --global user.name  2>$null } catch { $null }
$gitEmail = try { git config --global user.email 2>$null } catch { $null }

if ($gitName -and $gitEmail) {
    Write-Host "  $gitName <$gitEmail> (OK)" -ForegroundColor Green
} else {
    Write-Host "  Git identity not configured" -ForegroundColor Yellow
    if ($PSCmdlet.ShouldProcess("git identity", "Configure")) {
        $name  = $profile.identity.git.name  ?? "Server Admin"
        $email = $profile.identity.git.email ?? "admin@localhost"
        git config --global user.name "$name"
        git config --global user.email "$email"
        Write-Host "  Set: $name <$email>" -ForegroundColor Green
    }
}

# 5.5 Git autocrlf
Write-Host ""
$currentCrlf = try { git config --global core.autocrlf 2>$null } catch { $null }
if ($currentCrlf -ne "input") {
    if ($PSCmdlet.ShouldProcess("core.autocrlf=input", "Set git autocrlf")) {
        git config --global core.autocrlf input
        Write-Host "  Set core.autocrlf = input" -ForegroundColor Green
    }
} else {
    Write-Host "  core.autocrlf = input (OK)" -ForegroundColor Green
}

# 5.6 SSH
Write-Host ""
Write-Host "  5.6 SSH" -ForegroundColor Cyan
$sshDir = "$env:USERPROFILE\.ssh"
$keys = Get-ChildItem "$sshDir\id_*" -ErrorAction SilentlyContinue
if ($keys.Count -gt 0) {
    Write-Host "  SSH keys: $($keys.Count) found" -ForegroundColor Green
} else {
    Write-Host "  No SSH keys — generate with: ssh-keygen -t ed25519" -ForegroundColor Yellow
}

Write-Host ""
Write-Host ">>> 50 — server setup complete" -ForegroundColor Green
Write-Host "  Note: Server profile is minimal by design." -ForegroundColor DarkGray
Write-Host "  For full toolchain, use home or lab profile." -ForegroundColor DarkGray
