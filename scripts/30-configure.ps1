#!/usr/bin/env pwsh
# === scripts/30-configure.ps1 ================================
# ROLE:   Apply dotfiles, shell settings, environment configs
#         Aplikace konfigurací, profilů, proměnných prostředí
# RUN:    ./30-configure.ps1 -Force
# ==============================================================
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Force)

$logDir = Join-Path $env:USERPROFILE ".dev-env" "logs"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$logFile = Join-Path $logDir "configure-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Write-Log {
    param([string]$M, [string]$L="INFO")
    Add-Content -Path $logFile -Value "[$(Get-Date -Format 'HH:mm:ss')] [$L] $M" -Encoding UTF8
    switch($L){ "ERROR"{Write-Host $M -ForegroundColor Red} "WARN"{Write-Host $M -ForegroundColor Yellow} default{Write-Host $M -ForegroundColor DarkGray} }
}
Write-Log "30-configure started" "INFO"

Write-Host "─── 30 — CONFIGURE / Konfigurace ────────────────────" -ForegroundColor Cyan
$changes = 0

# 1. PowerShell profil
$psProfileDir = Split-Path $PROFILE -Parent
$psProfilePath = $PROFILE
$repoProfile = Join-Path $PSScriptRoot ".." "configs" "pwsh" "profile.ps1"

if (Test-Path $repoProfile) {
    if (-not (Test-Path $psProfileDir)) { New-Item -Path $psProfileDir -ItemType Directory -Force | Out-Null }
    if ($PSCmdlet.ShouldProcess("PowerShell profile", "Copy $repoProfile → $psProfilePath")) {
        Copy-Item -Path $repoProfile -Destination $psProfilePath -Force
        Write-Host "  ✅ PowerShell profil: $psProfilePath" -ForegroundColor Green
        Write-Log "PowerShell profile applied" "OK"; $changes++
    }
} else { Write-Host "  ℹ️  PowerShell profil nenalezen v repu" -ForegroundColor DarkGray }

# 2. Git config
$repoGitConfig = Join-Path $PSScriptRoot ".." "configs" "git" ".gitconfig"
if (Test-Path $repoGitConfig) {
    $gitConfigPath = Join-Path $env:USERPROFILE ".gitconfig"
    if ($PSCmdlet.ShouldProcess("Git config", "Copy $repoGitConfig → $gitConfigPath")) {
        Copy-Item -Path $repoGitConfig -Destination $gitConfigPath -Force
        Write-Host "  ✅ Git config: $gitConfigPath" -ForegroundColor Green
        Write-Log "Git config applied" "OK"; $changes++
    }
} else { Write-Host "  ℹ️  Git config nenalezen v repu" -ForegroundColor DarkGray }

# 3. Git autocrlf
$current = git config --global core.autocrlf 2>$null
if ($current -ne "input") {
    if ($PSCmdlet.ShouldProcess("Git autocrlf", "Set core.autocrlf=input")) {
        git config --global core.autocrlf input
        Write-Host "  ✅ Git autocrlf = input" -ForegroundColor Green
        Write-Log "Git autocrlf set to input" "OK"; $changes++
    }
} else { Write-Host "  ✅ Git autocrlf již nastaven" -ForegroundColor Green }

# 4. Git identity
$identityFile = Join-Path $env:USERPROFILE ".dev-env" "config" "identity.json"
if (Test-Path $identityFile) {
    try { $id = Get-Content $identityFile -Raw | ConvertFrom-Json
        if ($id.git -and $id.git.name -and $id.git.email) {
            if ($PSCmdlet.ShouldProcess("Git identity", "Set $($id.git.name) <$($id.git.email)>")) {
                git config --global user.name $id.git.name
                git config --global user.email $id.git.email
                Write-Host "  ✅ Git identita: $($id.git.name) <$($id.git.email)>" -ForegroundColor Green
                Write-Log "Git identity set" "OK"; $changes++
            }
        }
    } catch { Write-Host "  ⚠️  Identity file corrupted" -ForegroundColor Yellow }
} else { Write-Host "  ℹ️  Identity file nenalezen (spustit 50-setup-home.ps1)" -ForegroundColor DarkGray }

# 5. Starship prompt
if (Get-Command starship -ErrorAction SilentlyContinue) {
    $starshipConfig = Join-Path $env:USERPROFILE ".config" "starship.toml"
    $repoStarship = Join-Path $PSScriptRoot ".." "configs" "starship.toml"
    if (Test-Path $repoStarship) {
        $starshipDir = Split-Path $starshipConfig -Parent
        if (-not (Test-Path $starshipDir)) { New-Item -Path $starshipDir -ItemType Directory -Force | Out-Null }
        if ($PSCmdlet.ShouldProcess("Starship config", "Copy $repoStarship → $starshipConfig")) {
            Copy-Item -Path $repoStarship -Destination $starshipConfig -Force
            Write-Host "  ✅ Starship prompt: $starshipConfig" -ForegroundColor Green
            Write-Log "Starship config applied" "OK"; $changes++
        }
    }
}

# 6. HOME env
if (-not $env:HOME) {
    if ($PSCmdlet.ShouldProcess("HOME", "Set HOME=$env:USERPROFILE")) {
        [Environment]::SetEnvironmentVariable("HOME", $env:USERPROFILE, "User")
        $env:HOME = $env:USERPROFILE
        Write-Host "  ✅ HOME nastavena" -ForegroundColor Green
        Write-Log "HOME set" "OK"; $changes++
    }
} else { Write-Host "  ✅ HOME již nastavena" -ForegroundColor Green }

# 7. Vytvořit adresáře
$dirs = @("~\dev\projects", "~\bin", "~\.dev-env\config")
foreach ($d in $dirs) {
    $exp = [Environment]::ExpandEnvironmentVariables($d.Replace("~", $env:USERPROFILE))
    if (-not (Test-Path $exp)) {
        if ($PSCmdlet.ShouldProcess($d, "Create directory")) {
            New-Item -Path $exp -ItemType Directory -Force | Out-Null
            Write-Host "  📁 $d" -ForegroundColor Green; $changes++
        }
    }
}

Write-Log "30-configure complete: $changes changes" "INFO"
Write-Host ""
Write-Host ">>> 30 — configure OK ($changes changes)" -ForegroundColor Green
exit 0
