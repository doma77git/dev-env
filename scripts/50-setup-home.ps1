#!/usr/bin/env pwsh
# === scripts/50-setup-home.ps1 ================================
# ROLE:   Home PC setup — winget install by category + symlink + folders
#         Instalace domácího PC podle kategorií
# RUN:    ./50-setup-home.ps1 -WhatIf
#         ./50-setup-home.ps1 -IncludeRequired -IncludeRecommended
#         ./50-setup-home.ps1 -Force
# ==============================================================
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$IncludeRequired,        # Nutné (výchozí: dle preferences)
    [switch]$IncludeRecommended,     # Doporučené (výchozí: dle preferences)
    [switch]$IncludeOptional,        # Nepovinné
    [switch]$IncludeDev,             # Vývojářské
    [switch]$Force
)

$profilePath = Join-Path $PSScriptRoot ".." "profiles" "home.json"
$profile = Get-Content $profilePath -Raw | ConvertFrom-Json

# ─── Software categories (sdílená data s 10-detect.ps1) ──────
$softwareCategories = [ordered]@{
    required = @(
        @{ name = "git";    winget = "Git.Git";                  desc = "Git version control" }
        @{ name = "pwsh";   winget = "Microsoft.PowerShell";      desc = "PowerShell 7" }
        @{ name = "wt";     winget = "Microsoft.WindowsTerminal"; desc = "Windows Terminal" }
    )
    recommended = @(
        @{ name = "code";     winget = "Microsoft.VisualStudioCode"; desc = "VS Code editor" }
        @{ name = "7z";       winget = "7zip.7zip";                  desc = "7-Zip archiver" }
        @{ name = "chrome";   winget = "Google.Chrome";              desc = "Chrome browser" }
        @{ name = "notepad++";winget = "Notepad++.Notepad++";        desc = "Notepad++ editor" }
        @{ name = "gh";       winget = "GitHub.cli";                 desc = "GitHub CLI" }
        @{ name = "curl";     winget = "curl";                       desc = "cURL" }
    )
    optional = @(
        @{ name = "nvim";     winget = "Neovim.Neovim";          desc = "Neovim editor" }
        @{ name = "docker";   winget = "Docker.DockerDesktop";    desc = "Docker Desktop" }
        @{ name = "starship"; winget = "Starship.Starship";       desc = "Starship prompt" }
    )
    dev = @(
        @{ name = "node";     winget = "OpenJS.NodeJS.LTS";      desc = "Node.js" }
        @{ name = "python";   winget = "Python.Python.3.12";     desc = "Python 3.12" }
        @{ name = "vs2022";   winget = "Microsoft.VisualStudio.2022.Community"; desc = "Visual Studio 2022" }
        @{ name = "rider";    winget = "JetBrains.Rider";        desc = "JetBrains Rider" }
        @{ name = "postman";  winget = "Postman.Postman";        desc = "Postman API" }
    )
}

Write-Host ">>> PHASE 50 — PACKAGE SETUP (home) / INSTALACE" -ForegroundColor Green
Write-Host "  Home PC — winget install, folders, git config, autocrlf" -ForegroundColor DarkGray
Write-Host ""

# ─── Načtení preferencí ───────────────────────────────────────
$prefFile = Join-Path $env:USERPROFILE ".dev-env" "software-preferences.json"
if (Test-Path $prefFile) {
    try { $prefs = Get-Content $prefFile -Raw | ConvertFrom-Json } catch { $prefs = $null }
}
if (-not $prefs) {
    $prefs = [pscustomobject]@{ categories = [pscustomobject]@{ required=$true; recommended=$true; optional=$false; dev=$false } }
}
if (-not $PSBoundParameters.ContainsKey('IncludeRequired'))    { $IncludeRequired = $prefs.categories.required }
if (-not $PSBoundParameters.ContainsKey('IncludeRecommended')) { $IncludeRecommended = $prefs.categories.recommended }
if (-not $PSBoundParameters.ContainsKey('IncludeOptional'))    { $IncludeOptional = $prefs.categories.optional }
if (-not $PSBoundParameters.ContainsKey('IncludeDev'))         { $IncludeDev = $prefs.categories.dev }

$activeCats = @()
if ($IncludeRequired)    { $activeCats += "🔴REQ" }
if ($IncludeRecommended) { $activeCats += "🟡REC" }
if ($IncludeOptional)    { $activeCats += "🟢OPT" }
if ($IncludeDev)         { $activeCats += "🔵DEV" }
Write-Host "  Kategorie: $($activeCats -join ' ')" -ForegroundColor DarkGray

# ─── 1. HOME env variable ────────────────────────────────────
Write-Host "5.1 HOME environment variable" -ForegroundColor Cyan
if ($env:HOME -and $env:HOME -ne $env:USERPROFILE) {
    Write-Host "  HOME = $env:HOME" -ForegroundColor Green
} elseif ($env:HOME -eq $env:USERPROFILE) {
    Write-Host "  HOME = USERPROFILE (OK)" -ForegroundColor Yellow
} else {
    Write-Host "  HOME not set / nenastaveno" -ForegroundColor Red
    if ($PSCmdlet.ShouldProcess("$env:USERPROFILE", "Set HOME environment variable")) {
        [Environment]::SetEnvironmentVariable("HOME", $env:USERPROFILE, "User")
        Write-Host "  FIXED" -ForegroundColor Green
    }
}

# ─── 2. Directories / složky ────────────────────────────────
Write-Host "5.2 Directories / složky" -ForegroundColor Cyan
$dirs = @(
    "~\dev\projects\osobni", "~\dev\projects\ppg", "~\dev\projects\lab",
    "~\.config\powershell", "~\bin", "~\.dev-env\config",
    "~\Documents\downloads\_temp", "~\Documents\downloads\keep",
    "~\Documents\docs\navody", "~\Documents\docs\architektura",
    "~\Documents\chat-exports"
)
foreach ($d in $dirs) {
    $expanded = [Environment]::ExpandEnvironmentVariables($d.Replace("~", $env:USERPROFILE))
    if (Test-Path $expanded) { Write-Host "  OK  $d" -ForegroundColor Green }
    else {
        Write-Host "  NEW $d" -ForegroundColor Yellow
        if ($PSCmdlet.ShouldProcess($d, "Create directory")) {
            New-Item -ItemType Directory -Path $expanded -Force | Out-Null
        }
    }
}

# ─── 3. Category-based package installation ─────────────────
Write-Host "5.3 Packages by category / balíčky" -ForegroundColor Cyan
function Test-Installed($name) { $null -ne (Get-Command $name -ErrorAction SilentlyContinue) }

$catIcons = @{ required="🔴"; recommended="🟡"; optional="🟢"; dev="🔵" }
$catLabels = @{ required="NUTNÉ"; recommended="DOPORUČENÉ"; optional="NEPOVINNÉ"; dev="VÝVOJÁŘSKÉ" }
$selectedCats = @()
if ($IncludeRequired)    { $selectedCats += "required" }
if ($IncludeRecommended) { $selectedCats += "recommended" }
if ($IncludeOptional)    { $selectedCats += "optional" }
if ($IncludeDev)         { $selectedCats += "dev" }

$totalInstalled = 0; $totalMissing = 0
foreach ($cat in $selectedCats) {
    Write-Host ""
    Write-Host "  $($catIcons[$cat]) $($catLabels[$cat])" -ForegroundColor Cyan
    foreach ($pkg in $softwareCategories[$cat]) {
        $installed = Test-Installed $pkg.name
        if ($installed) { $totalInstalled++; Write-Host "    ✅  $($pkg.name) ($($pkg.winget))" -ForegroundColor Green }
        else {
            $totalMissing++
            Write-Host "    ❌  $($pkg.name) ($($pkg.winget))" -ForegroundColor Yellow
            if ($PSCmdlet.ShouldProcess($pkg.name, "Install $($pkg.winget)")) {
                Write-Host "         🔧 Instaluji ..." -NoNewline -ForegroundColor Cyan
                try {
                    $result = winget install --id $pkg.winget --accept-source-agreements --silent 2>&1
                    if ($LASTEXITCODE -eq 0) { Write-Host " OK" -ForegroundColor Green }
                    else { Write-Host " FAIL ($LASTEXITCODE)" -ForegroundColor Red }
                } catch { Write-Host " ERROR: $_" -ForegroundColor Red }
            }
        }
    }
}
Write-Host ""
Write-Host "  Souhrn: $totalInstalled nainstalováno, $totalMissing chybí" -ForegroundColor $(if($totalMissing -eq 0){'Green'}else{'Yellow'})

# ─── 4. Config symlinks / symlinky ──────────────────────────
Write-Host "5.4 Config symlinks / symlinky" -ForegroundColor Cyan
$linkScript = Join-Path $PSScriptRoot "link-configs.ps1"
if (Test-Path $linkScript) { & $linkScript -WhatIf:$WhatIfPreference -Force:$Force }

# ─── 5. Git config / globální nastavení ────────────────────
Write-Host "5.5 Git identity / identita" -ForegroundColor Cyan
$identityFile = Join-Path $env:USERPROFILE ".dev-env" "config" "identity.json"
$savedId = if (Test-Path $identityFile) { try { Get-Content $identityFile -Raw | ConvertFrom-Json } catch { $null } } else { $null }
if ($savedId -and $savedId.git.email) {
    $gitName = $savedId.git.name; $gitEmail = $savedId.git.email
    Write-Host "  Using saved identity: $gitName <$gitEmail>" -ForegroundColor DarkCyan
} else {
    $gitCfgName = try { git config --global user.name 2>$null } catch { $null }
    $gitCfgEmail = try { git config --global user.email 2>$null } catch { $null }
    if ($gitCfgName -and $gitCfgEmail) {
        $gitName = $gitCfgName; $gitEmail = $gitCfgEmail
        Write-Host "  Using git-config identity: $gitName <$gitEmail>" -ForegroundColor DarkCyan
    } else {
        $gitName = $profile.identity.git.name; $gitEmail = $profile.identity.git.email
        Write-Host "  Using profile default: $gitName <$gitEmail>" -ForegroundColor Yellow
    }
}
if ($PSCmdlet.ShouldProcess("$gitName <$gitEmail>", "Set git identity")) {
    git config --global user.name "$gitName"
    git config --global user.email "$gitEmail"
    $null = New-Item -ItemType Directory -Path (Split-Path $identityFile -Parent) -Force
    @{ git = @{ name = $gitName; email = $gitEmail } } | ConvertTo-Json | Set-Content $identityFile -Encoding UTF8
    Write-Host "  Set: $gitName <$gitEmail>" -ForegroundColor Green
} else {
    $current = git config --global user.name 2>$null
    $currentEmail = git config --global user.email 2>$null
    Write-Host "  Current: $current <$currentEmail>" -ForegroundColor Yellow
}

# ─── 6. Git autocrlf ────────────────────────────────────────
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

# ─── Uložit preference ──────────────────────────────────────
@{
    categories = @{
        required    = [bool]$IncludeRequired
        recommended = [bool]$IncludeRecommended
        optional    = [bool]$IncludeOptional
        dev         = [bool]$IncludeDev
    }
} | ConvertTo-Json -Depth 3 | Out-File $prefFile -Encoding UTF8

Write-Host ""
Write-Host "  💾  Preference uloženy: $prefFile" -ForegroundColor DarkGray
Write-Host ""
Write-Host ">>> 50 — package-setup (home) OK" -ForegroundColor Green
if ($Force)   { Write-Host "  packages installed, proceeding with phase 60" -ForegroundColor DarkGray }
if ($WhatIfPreference) { Write-Host "  dry-run complete" -ForegroundColor DarkGray }
Write-Host "=== DONE ===" -ForegroundColor Green
