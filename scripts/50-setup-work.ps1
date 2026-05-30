#!/usr/bin/env pwsh
# === scripts/50-setup-work.ps1 ================================
# ROLE:   Corporate PC (PPG) setup — no winget, proxy, VPN
#         Instalace firemního PC
# RUN:    ./50-setup-work.ps1 -WhatIf     (dry run / suchý běh)
#         ./50-setup-work.ps1 -Force      (apply / aplikovat)
#         ./50-setup-work.ps1 -Confirm    (potvrzovat každou změnu)
# ==============================================================
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Force)

$profile = Get-Content (Join-Path $PSScriptRoot ".." "profiles" "work.json") -Raw | ConvertFrom-Json

Write-Host ">>> PHASE 50 — PACKAGE SETUP (work) / INSTALACE FIREMNÍ" -ForegroundColor Green
Write-Host ""

# 1. Proxy environment variables
Write-Host "5.1 Proxy / proxy proměnné" -ForegroundColor Cyan
$proxyUrl = $profile.proxy  # "http://proxy.ppg.com:8080"
if ($proxyUrl) {
    $envVars = @("HTTP_PROXY", "HTTPS_PROXY", "http_proxy", "https_proxy")
    $setCount = 0
    foreach ($var in $envVars) {
        if ([Environment]::GetEnvironmentVariable($var, "User") -eq $proxyUrl) {
            Write-Host "  OK  $var = $proxyUrl" -ForegroundColor Green
            $setCount++
        } else {
            Write-Host "  MISS $var" -ForegroundColor Yellow
            if ($PSCmdlet.ShouldProcess("$var = $proxyUrl", "Set environment variable")) {
                [Environment]::SetEnvironmentVariable($var, $proxyUrl, "User")
                Write-Host "  Set $var = $proxyUrl" -ForegroundColor DarkCyan
            }
        }
    }
    # Git proxy
    $gitProxy = git config --global http.proxy 2>$null
    if ($gitProxy -eq $proxyUrl) {
        Write-Host "  OK  git http.proxy = $proxyUrl" -ForegroundColor Green
    } else {
        Write-Host "  MISS git http.proxy" -ForegroundColor Yellow
        if ($PSCmdlet.ShouldProcess("git http.proxy = $proxyUrl", "Set git proxy")) {
            git config --global http.proxy $proxyUrl
            Write-Host "  Set git http.proxy" -ForegroundColor DarkCyan
        }
    }
} else {
    Write-Host "  No proxy configured / proxy není nastaven" -ForegroundColor Yellow
}

# 2. VPN check
Write-Host "5.2 VPN / připojení VPN" -ForegroundColor Cyan
$vpnRequired = $profile.vpn.required  # true
$vpnClient   = $profile.vpn.client    # "Cisco AnyConnect"
if ($vpnRequired) {
    $vpnProcesses = @("vpnui", "vpnagent", "Cisco AnyConnect Secure Mobility Client")
    $found = $false
    foreach ($p in $vpnProcesses) {
        if (Get-Process -Name $p -ErrorAction SilentlyContinue) {
            Write-Host "  OK  VPN client running: $p" -ForegroundColor Green
            $found = $true
            break
        }
    }
    if (-not $found) {
        Write-Host "  ⚠  VPN client ($vpnClient) not running / neběží" -ForegroundColor Yellow
        Write-Host "      Internal resources (GitLab, npm registry) may be unreachable." -ForegroundColor Yellow
        Write-Host "      Connect VPN before bootstrap. / Připoj VPN před bootstrapem." -ForegroundColor Yellow
    }
} else {
    Write-Host "  VPN not required / VPN není vyžadována" -ForegroundColor Green
}

# 3. Manual install checklist (no winget in corporate)
Write-Host "5.3 Manual install checklist / manuální instalace" -ForegroundColor Cyan
$manualTools = @(
    @{ Name = "Git";             Url = "https://git-scm.com/download/win";                      Test = "git --version" },
    @{ Name = "PowerShell 7+";   Url = "https://github.com/PowerShell/PowerShell/releases";      Test = "pwsh --version" },
    @{ Name = "VS Code";         Url = "https://code.visualstudio.com/download";                 Test = "code --version" },
    @{ Name = "Node.js LTS";     Url = "https://nodejs.org/";                                    Test = "node --version" },
    @{ Name = "Python 3";        Url = "https://www.python.org/downloads/";                      Test = "python --version" },
    @{ Name = "GitHub CLI";      Url = "https://cli.github.com/";                                Test = "gh --version" },
    @{ Name = "curl";            Url = "https://curl.se/windows/";                               Test = "curl --version" },
    @{ Name = "7-Zip";           Url = "https://www.7-zip.org/download.html";                    Test = "7z --help" }
)
foreach ($tool in $manualTools) {
    $installed = $null
    try { $installed = Get-Command ($tool.Test.Split(' ')[0]) -ErrorAction SilentlyContinue } catch {}
    if ($installed) {
        Write-Host "  OK  $($tool.Name)" -ForegroundColor Green
    } else {
        Write-Host "  MISS $($tool.Name)" -ForegroundColor Yellow
        Write-Host "       $($tool.Url)" -ForegroundColor DarkGray
    }
}

# 4. ExecutionPolicy
Write-Host "5.4 ExecutionPolicy / zásady spouštění" -ForegroundColor Cyan
$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
$targetPolicy = $profile.restrictions.executionPolicy  # "RemoteSigned"
if ($currentPolicy -eq $targetPolicy) {
    Write-Host "  OK  ExecutionPolicy = $currentPolicy" -ForegroundColor Green
} else {
    Write-Host "  CHG ExecutionPolicy = $currentPolicy → $targetPolicy" -ForegroundColor Yellow
    if ($PSCmdlet.ShouldProcess("ExecutionPolicy $targetPolicy", "Set execution policy")) {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy $targetPolicy -Force
        Write-Host "  Set" -ForegroundColor DarkCyan
    }
}

# 5. Directories / složky (corporate paths)
Write-Host "5.5 Directories / složky" -ForegroundColor Cyan
$dirs = @(
    "~\dev\projects\ppg",
    "~\dev\projects\lab",
    "~\.config\powershell",
    "~\bin",
    "~\.dev-env\config",
    "~\Documents\downloads\_temp",
    "~\Documents\docs\architektura",
    "~\Documents\chat-exports"
)
foreach ($d in $dirs) {
    $expanded = [Environment]::ExpandEnvironmentVariables($d.Replace("~", $env:USERPROFILE))
    if (Test-Path $expanded) {
        Write-Host "  OK  $d" -ForegroundColor Green
    } else {
        Write-Host "  NEW $d" -ForegroundColor Yellow
        if ($PSCmdlet.ShouldProcess($d, "Create directory")) {
            New-Item -ItemType Directory -Path $expanded -Force | Out-Null
            Write-Host "  Created" -ForegroundColor DarkCyan
        }
    }
}

# 6. Symlink configs
Write-Host "5.6 Config symlinks / symlinky" -ForegroundColor Cyan
& "$PSScriptRoot\link-configs.ps1" -WhatIf:$WhatIf -Force:$Force

Write-Host ""
Write-Host ""
Write-Host ">>> 50 — package-setup (work) OK" -ForegroundColor Green
if ($Force)   { Write-Host "  packages installed, proceeding with phase 60" -ForegroundColor DarkGray }
if ($WhatIf)  { Write-Host "  dry-run complete, review above then run with -Force" -ForegroundColor DarkGray }
if (-not $Force -and -not $WhatIf) { Write-Host "  review above then run with -WhatIf or -Force" -ForegroundColor DarkGray }
Write-Host "=== DONE / HOTOVO ===" -ForegroundColor Green
if (-not $Force -and -not $WhatIf) {
    Write-Host "  Run with -WhatIf or -Force / Spust s -WhatIf nebo -Force" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  ⚠  CORPORATE NOTES:" -ForegroundColor Yellow
    Write-Host "  • Winget is blocked — install tools manually from the URLs above" -ForegroundColor Yellow
    Write-Host "  • Proxy configured — check VPN is connected first" -ForegroundColor Yellow
    Write-Host "  • GPO may block irm/iex — use Set-ExecutionPolicy -Scope Process" -ForegroundColor Yellow
    Write-Host "  • Some features require IT admin approval" -ForegroundColor Yellow
}