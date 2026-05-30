#!/usr/bin/env pwsh
# === scripts/50-setup-home.ps1 ================================
# ROLE:   Home PC setup — winget install + symlink + folders
#         Instalace domácího PC
# RUN:    ./50-setup-home.ps1 -WhatIf    (dry run / suchý běh)
#         ./50-setup-home.ps1 -Force     (apply / aplikovat)
#         ./50-setup-home.ps1 -Confirm   (potvrzovat každou změnu)
# ==============================================================
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Force)

$profile = Get-Content (Join-Path $PSScriptRoot ".." "profiles" "home.json") -Raw | ConvertFrom-Json

Write-Host ">>> PHASE 50 — PACKAGE SETUP (home) / INSTALACE" -ForegroundColor Green
Write-Host "  Home PC — winget install, folders, git config, autocrlf" -ForegroundColor DarkGray
Write-Host ""

# 1. HOME env variable
Write-Host "5.1 HOME environment variable" -ForegroundColor Cyan
if ($env:HOME -and $env:HOME -ne $env:USERPROFILE) {
    Write-Host "  HOME = $env:HOME" -ForegroundColor Green
} elseif ($env:HOME -eq $env:USERPROFILE) {
    Write-Host "  HOME = USERPROFILE (OK)" -ForegroundColor Yellow
} else {
    Write-Host "  HOME not set / nenastaveno" -ForegroundColor Red
    if ($PSCmdlet.ShouldProcess("$env:USERPROFILE", "Set HOME environment variable")) {
        Write-Host "  Setting HOME = $env:USERPROFILE" -ForegroundColor Yellow
        [Environment]::SetEnvironmentVariable("HOME", $env:USERPROFILE, "User")
    }
}

# 2. Directories / složky
Write-Host "5.2 Directories / složky" -ForegroundColor Cyan
$dirs = @(
    "~\dev\projects\osobni",
    "~\dev\projects\ppg",
    "~\dev\projects\lab",
    "~\.config\powershell",
    "~\bin",
    "~\.dev-env\config",
    "~\Documents\downloads\_temp",
    "~\Documents\downloads\keep",
    "~\Documents\docs\navody",
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
        }
    }
}

# 3. Packages by category / balíčky podle kategorií
Write-Host "5.3 Packages by category / balíčky" -ForegroundColor Cyan

# Winget package ID mapping
$wingetMap = @{
    "wt"       = "Microsoft.WindowsTerminal"
    "pwsh"     = "Microsoft.PowerShell"
    "chrome"   = "Google.Chrome"
    "reasonix" = "Reasonix.Reasonix"
    "deepseek" = "DeepSeek.DeepSeek"
    "notepad++"= "Notepad++.Notepad++"
    "code"     = "Microsoft.VisualStudioCode"
    "nvim"     = "Neovim.Neovim"
    "git"      = "Git.Git"
    "gh"       = "GitHub.cli"
    "node"     = "OpenJS.NodeJS.LTS"
    "python"   = "Python.Python.3.12"
    "docker"   = "Docker.DockerDesktop"
    "curl"     = "curl"
    "7z"       = "7zip.7zip"
    "starship" = "Starship.Starship"
}

# Category definitions
$categories = [ordered]@{
    "🖥️  TERMINAL" = @{
        tools = @("wt", "pwsh")
        priority = "core"
        desc = "Minimální kostra — vždy navrženo"
    }
    "🌐  BROWSER"  = @{
        tools = @("chrome")
        priority = "recommended"
        desc = "Doporučený prohlížeč"
    }
    "🤖  AI"       = @{
        tools = @("reasonix")
        priority = "recommended"
        desc = "AI nástroje — Reasonix doporučen"
    }
    "📝  EDITORS"  = @{
        tools = @("notepad++")
        priority = "recommended"
        desc = "Editory — Notepad++ doporučen"
    }
    "🔧  PROJECT"  = @{
        tools = @("git")
        priority = "recommended"
        desc = "Projektová manipulace — git doporučen"
    }
    "📦  UTILS"    = @{
        tools = @("curl", "7z")
        priority = "recommended"
        desc = "Utility"
    }
}

# Process each category
foreach ($catName in $categories.Keys) {
    $cat = $categories[$catName]
    Write-Host ""
    Write-Host "  $catName — $($cat.desc)" -ForegroundColor DarkCyan
    
    $allOk = $true
    $missing = @()
    
    foreach ($tool in $cat.tools) {
        $pkgId = $wingetMap[$tool]
        if (-not $pkgId) { 
            Write-Host "    ⚠  $tool — no winget mapping, skip" -ForegroundColor DarkYellow
            continue 
        }
        
        $installed = winget list --id $pkgId 2>$null | Select-String -SimpleMatch $pkgId
        if ($installed) {
            Write-Host "    ✅  $tool ($pkgId)" -ForegroundColor Green
        } else {
            Write-Host "    ❌  $tool ($pkgId)" -ForegroundColor Yellow
            $allOk = $false
            $missing += $pkgId
        }
    }
    
    if ($missing.Count -gt 0 -and $PSCmdlet.ShouldProcess($missing -join ', ', "Install packages")) {
        foreach ($pkgId in $missing) {
            Write-Host "    Installing $pkgId ..." -ForegroundColor Yellow
            winget install --id $pkgId --accept-source-agreements 2>&1 | Out-Null
        }
    }
}

# AI optional: deepseek
Write-Host ""
Write-Host "  🤖  AI (optional) — deepseek" -ForegroundColor DarkGray
$dsId = $wingetMap["deepseek"]
$dsInstalled = winget list --id $dsId 2>$null | Select-String -SimpleMatch $dsId
if ($dsInstalled) {
    Write-Host "    ✅  deepseek ($dsId)" -ForegroundColor Green
} else {
    Write-Host "    ⬚  deepseek ($dsId) — optional, run manually if wanted" -ForegroundColor DarkGray
}

# Editors optional: code, nvim
Write-Host ""
Write-Host "  📝  EDITORS (optional) — code, nvim" -ForegroundColor DarkGray
foreach ($opt in @("code", "nvim")) {
    $optId = $wingetMap[$opt]
    $optInstalled = winget list --id $optId 2>$null | Select-String -SimpleMatch $optId
    if ($optInstalled) {
        Write-Host "    ✅  $opt ($optId)" -ForegroundColor Green
    } else {
        Write-Host "    ⬚  $opt ($optId) — optional" -ForegroundColor DarkGray
    }
}

# Project optional: gh, node, python, docker
Write-Host ""
Write-Host "  🔧  PROJECT (optional) — gh, node, python, docker" -ForegroundColor DarkGray
foreach ($opt in @("gh", "node", "python", "docker")) {
    $optId = $wingetMap[$opt]
    $optInstalled = winget list --id $optId 2>$null | Select-String -SimpleMatch $optId
    if ($optInstalled) {
        Write-Host "    ✅  $opt ($optId)" -ForegroundColor Green
    } else {
        Write-Host "    ⬚  $opt ($optId) — optional" -ForegroundColor DarkGray
    }
}

# Utils optional: starship
Write-Host ""
Write-Host "  📦  UTILS (optional) — starship" -ForegroundColor DarkGray
$stId = $wingetMap["starship"]
$stInstalled = winget list --id $stId 2>$null | Select-String -SimpleMatch $stId
if ($stInstalled) {
    Write-Host "    ✅  starship ($stId)" -ForegroundColor Green
} else {
    Write-Host "    ⬚  starship ($stId) — optional" -ForegroundColor DarkGray
}

# 4. Symlink configs / konfigy
Write-Host "5.4 Config symlinks / symlinky" -ForegroundColor Cyan
& "$PSScriptRoot\link-configs.ps1" -WhatIf:$WhatIf -Force:$Force

# 5. Git config / globální nastavení
Write-Host "5.5 Git identity / identita" -ForegroundColor Cyan
# Resolve identity: saved > git-config > profile default
$identityFile = Join-Path $env:USERPROFILE ".dev-env" "config" "identity.json"
$savedId = if (Test-Path $identityFile) { try { Get-Content $identityFile -Raw | ConvertFrom-Json } catch { $null } } else { $null }
if ($savedId -and $savedId.git.email) {
    $gitName  = $savedId.git.name
    $gitEmail = $savedId.git.email
    Write-Host "  Using saved identity: $gitName <$gitEmail>" -ForegroundColor DarkCyan
} else {
    $gitCfgName  = try { git config --global user.name  2>$null } catch { $null }
    $gitCfgEmail = try { git config --global user.email 2>$null } catch { $null }
    if ($gitCfgName -and $gitCfgEmail -and $gitCfgEmail -ne 'jan@novak.cz' -and $gitCfgEmail -ne 'jan.novak@ppg.com') {
        $gitName  = $gitCfgName
        $gitEmail = $gitCfgEmail
        Write-Host "  Using git-config identity: $gitName <$gitEmail>" -ForegroundColor DarkCyan
    } else {
        $gitName  = $profile.identity.git.name
        $gitEmail = $profile.identity.git.email
        Write-Host "  Using profile default: $gitName <$gitEmail> (PLACEHOLDER)" -ForegroundColor Yellow
    }
}
if ($PSCmdlet.ShouldProcess("$gitName <$gitEmail>", "Set git identity")) {
    git config --global user.name "$gitName"
    git config --global user.email "$gitEmail"
    Write-Host "  Set: $gitName <$gitEmail>" -ForegroundColor Green
    # Save identity so profile.ps1 detects it on next run
    $null = New-Item -ItemType Directory -Path (Split-Path $identityFile -Parent) -Force
    @{ git = @{ name = $gitName; email = $gitEmail } } | ConvertTo-Json | Set-Content $identityFile -Encoding UTF8
    Write-Host "  Saved → ~/.dev-env/config/identity.json" -ForegroundColor DarkCyan
} else {
    $current = git config --global user.name 2>$null
    $currentEmail = git config --global user.email 2>$null
    Write-Host "  Current: $current <$currentEmail>" -ForegroundColor Yellow
}

# 6. Git autocrlf / konce řádků
Write-Host "5.6 Git core.autocrlf / konce řádků" -ForegroundColor Cyan
$currentAutocrlf = git config --global core.autocrlf 2>$null
if ($currentAutocrlf -eq "input") {
    Write-Host "  OK  core.autocrlf = input" -ForegroundColor Green
} else {
    Write-Host "  CHG core.autocrlf = $($currentAutocrlf ?? 'not set') → input" -ForegroundColor Yellow
    if ($PSCmdlet.ShouldProcess("core.autocrlf=input", "Set git autocrlf")) {
        git config --global core.autocrlf input
        Write-Host "  Set core.autocrlf = input" -ForegroundColor DarkCyan
    }
}

Write-Host ""
Write-Host ""
Write-Host ">>> 50 — package-setup (home) OK" -ForegroundColor Green
if ($Force)   { Write-Host "  packages installed, proceeding with phase 60" -ForegroundColor DarkGray }
if ($WhatIf)  { Write-Host "  dry-run complete, review above then run with -Force" -ForegroundColor DarkGray }
if (-not $Force -and -not $WhatIf) { Write-Host "  review above then run with -WhatIf or -Force" -ForegroundColor DarkGray }
Write-Host "=== DONE ===" -ForegroundColor Green