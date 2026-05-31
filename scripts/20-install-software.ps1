#!/usr/bin/env pwsh
# === scripts/20-install-software.ps1 ===========================
# ROLE:   Install missing software via winget by category
#         Instalace chybějícího SW přes winget podle kategorií
# RUN:    ./20-install-software.ps1 -IncludeRequired [-Force] [-Confirm]
# INPUT:  -IncludeRequired, -IncludeRecommended, -IncludeOptional, -IncludeDev
#         -Force (skip all confirmations), -Confirm (ask per package)
# OUTPUT: Exit code 0=all installed, 1=some failed
#         Log in ~/.dev-env/logs/install-*.log
# ==============================================================
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$IncludeRequired,
    [switch]$IncludeRecommended,
    [switch]$IncludeOptional,
    [switch]$IncludeDev,
    [switch]$ExportPackages,
    [switch]$ImportPackages,
    [switch]$Force,
    [switch]$SkipLog
)

# ─── Cesty ─────────────────────────────────────────────────────
$logDir = Join-Path $env:USERPROFILE ".dev-env" "logs"
$invPath = Join-Path $env:USERPROFILE ".dev-env" "software-inventory.json"
$prefPath = Join-Path $env:USERPROFILE ".dev-env" "software-preferences.json"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$logFile = Join-Path $logDir "install-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    Add-Content -Path $logFile -Value "[$ts] [$Level] $Message" -Encoding UTF8
    if (-not $SkipLog) { switch($Level){ "ERROR"{Write-Host $Message -ForegroundColor Red} "WARN"{Write-Host $Message -ForegroundColor Yellow} "OK"{Write-Host $Message -ForegroundColor Green} default{Write-Host $Message -ForegroundColor DarkGray} } }
}
Write-Log "20-install-software started" "INFO"

# ─── SafeMode check ──────────────────────────────────────────
$profilePath = Join-Path $env:USERPROFILE ".dev-env" "config" "profile.json"
if (Test-Path $profilePath) {
    try {
        $profile = Get-Content $profilePath -Raw | ConvertFrom-Json
        if ($profile.safeMode -and -not $Force) {
            Write-Host "❌ SAFE MODE ACTIVE ($($profile.type))" -ForegroundColor Red
            Write-Host "    Auto-install is BLOCKED on this machine." -ForegroundColor Yellow
            Write-Host "    Use -Force to override or switch profile." -ForegroundColor Yellow
            Write-Log "SafeMode blocked installation" "WARN"
            exit 1
        }
    } catch { Write-Log "SafeMode check failed: $_" "WARN" }
}

# ─── Software categories ──────────────────────────────────────
$Categories = @{
    required = @(
        @{ name = "git";    winget = "Git.Git";                  cmd = "git";    paths = @() }
        @{ name = "pwsh";   winget = "Microsoft.PowerShell";      cmd = "pwsh";   paths = @() }
        @{ name = "wt";     winget = "Microsoft.WindowsTerminal"; cmd = "wt";     paths = @("$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe") }
    )
    recommended = @(
        @{ name = "code";     winget = "Microsoft.VisualStudioCode"; cmd = "code";     paths = @("$env:ProgramFiles\Microsoft VS Code\Code.exe", "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe") }
        @{ name = "7z";       winget = "7zip.7zip";                  cmd = "7z";       paths = @("$env:ProgramFiles\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe") }
        @{ name = "chrome";   winget = "Google.Chrome";              cmd = "chrome";   paths = @("${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe") }
        @{ name = "notepad++";winget = "Notepad++.Notepad++";        cmd = "notepad++";paths = @("$env:ProgramFiles\Notepad++\notepad++.exe", "${env:ProgramFiles(x86)}\Notepad++\notepad++.exe") }
        @{ name = "gh";       winget = "GitHub.cli";                 cmd = "gh";       paths = @("$env:ProgramFiles\GitHub CLI\gh.exe") }
        @{ name = "curl";     winget = "curl";                       cmd = "curl";     paths = @() }
        @{ name = "reasonix"; winget = "Reasonix.Reasonix";           cmd = "reasonix"; paths = @("$env:LOCALAPPDATA\Programs\Reasonix\reasonix.exe") }
    )
    optional = @(
        @{ name = "nvim";     winget = "Neovim.Neovim";          cmd = "nvim";     paths = @("$env:ProgramFiles\Neovim\bin\nvim.exe","$env:LOCALAPPDATA\Neovim\bin\nvim.exe") }
        @{ name = "docker";   winget = "Docker.DockerDesktop";    cmd = "docker";   paths = @("$env:ProgramFiles\Docker\Docker\resources\bin\docker.exe") }
        @{ name = "starship"; winget = "Starship.Starship";       cmd = "starship"; paths = @("$env:ProgramFiles\starship\bin\starship.exe") }
    )
    dev = @(
        @{ name = "node";     winget = "OpenJS.NodeJS.LTS";      cmd = "node";     paths = @() }
        @{ name = "python";   winget = "Python.Python.3.12";     cmd = "python";   paths = @() }
        @{ name = "vs2022";   winget = "Microsoft.VisualStudio.2022.Community"; cmd = "devenv"; paths = @("$env:ProgramFiles\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe") }
        @{ name = "rider";    winget = "JetBrains.Rider";        cmd = "rider";    paths = @("$env:ProgramFiles\JetBrains\JetBrains Rider\bin\rider64.exe","$env:LOCALAPPDATA\JetBrains\JetBrains Rider\bin\rider64.exe") }
        @{ name = "postman";  winget = "Postman.Postman";        cmd = "postman";  paths = @("$env:LOCALAPPDATA\Postman\Postman.exe") }
    )
}

# ─── Načtení preferencí ───────────────────────────────────────
if (-not $IncludeRequired -and -not $IncludeRecommended -and -not $IncludeOptional -and -not $IncludeDev) {
    if (Test-Path $prefPath) { try { $p = Get-Content $prefPath -Raw | ConvertFrom-Json
        if ($p.required) { $IncludeRequired = $true }
        if ($p.recommended) { $IncludeRecommended = $true }
        if ($p.optional) { $IncludeOptional = $true }
        if ($p.dev) { $IncludeDev = $true }
    } catch {} }
    if (-not $IncludeRequired) { $IncludeRequired = $true }
    if (-not $IncludeRecommended) { $IncludeRecommended = $true }
}

$catKeys = @()
if ($IncludeRequired) { $catKeys += "required" }
if ($IncludeRecommended) { $catKeys += "recommended" }
if ($IncludeOptional) { $catKeys += "optional" }
if ($IncludeDev) { $catKeys += "dev" }

# ─── WinGet export / import ──────────────────────────────────
if ($ExportPackages) {
    $exportPath = Join-Path $env:USERPROFILE ".dev-env" "winget-export.json"
    Write-Host "📦 Exportuji nainstalované balíčky ..." -NoNewline -ForegroundColor Cyan
    try {
        winget export -o $exportPath 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Host " OK → $exportPath" -ForegroundColor Green; Write-Log "Exported packages to $exportPath" "INFO" }
        else { Write-Host " FAIL" -ForegroundColor Red }
    } catch { Write-Host " ERROR: $_" -ForegroundColor Red }
    exit 0
}

if ($ImportPackages) {
    $importPath = Join-Path $env:USERPROFILE ".dev-env" "winget-export.json"
    if (-not (Test-Path $importPath)) { Write-Host "❌ Export nenalezen: $importPath" -ForegroundColor Red; exit 1 }
    Write-Host "📦 Importuji balíčky z $importPath ..." -ForegroundColor Cyan
    if ($PSCmdlet.ShouldProcess("Import winget packages", "winget import")) {
        try {
            winget import -i $importPath --accept-package-agreements --silent 2>&1
            if ($LASTEXITCODE -eq 0) { Write-Host "  ✅ Import OK" -ForegroundColor Green; Write-Log "Imported packages from $importPath" "INFO" }
            else { Write-Host "  ❌ Import FAIL ($LASTEXITCODE)" -ForegroundColor Red }
        } catch { Write-Host "  ❌ Import ERROR: $_" -ForegroundColor Red }
    }
    exit 0
}

# ─── Detekce nainstalovaných ─────────────────────────────────
$Inventory = @{}
if (Test-Path $invPath) { try { $Inventory = Get-Content $invPath -Raw | ConvertFrom-Json } catch {} }

function Test-Installed($app) {
    if (Get-Command $app.cmd -ErrorAction SilentlyContinue) { return $true }
    foreach ($p in $app.paths) { if (Test-Path $p) { return $true } }
    if ($Inventory.($app.name) -eq $true) { return $true }
    return $false
}

# ─── Instalace ────────────────────────────────────────────────
$installQueue = @()
foreach ($key in $catKeys) {
    foreach ($app in $Categories[$key]) {
        if (-not (Test-Installed $app)) { $installQueue += @{ App = $app; Category = $key } }
    }
}

Write-Host "📦 $($installQueue.Count) aplikací k instalaci" -ForegroundColor Cyan
foreach ($q in $installQueue) {
    Write-Host "  ☐ $($q.App.name) [$($q.Category)]" -ForegroundColor Yellow
}

if ($installQueue.Count -eq 0) { Write-Host "✅ Všechno již nainstalováno" -ForegroundColor Green; exit 0 }

# WhatIf early exit
if ($WhatIfPreference) {
    Write-Host "`n[WhatIf] Would install $($installQueue.Count) packages:" -ForegroundColor Cyan
    foreach ($q in $installQueue) { Write-Host "  - $($q.App.name) ($($q.App.winget)) [$($q.Category)]" -ForegroundColor Yellow }
    Write-Host "[WhatIf] No changes made. Exiting." -ForegroundColor Cyan
    exit 0
}

if (-not $Force) {
    Write-Host "`nPro instalaci použij -Force" -ForegroundColor Yellow; exit 0
}

$ok = 0
foreach ($q in $installQueue) {
    $app = $q.App
    $action = "Install $($app.name) ($($app.winget))"
    if (-not $PSCmdlet.ShouldProcess($action, "winget install")) { continue }
    
    Write-Host "  📦 $($app.name) ... " -NoNewline
    try {
        $r = winget install $app.winget --accept-package-agreements --accept-source-agreements --silent 2>&1
        if ($LASTEXITCODE -eq 0) { Write-Host "OK" -ForegroundColor Green; $ok++; Write-Log "Installed $($app.name)" "OK"
            $Inventory | Add-Member -NotePropertyName $app.name -NotePropertyValue $true -Force
        } else { Write-Host "FAIL ($LASTEXITCODE)" -ForegroundColor Red; Write-Log "Failed $($app.name): $(($r|Select-Object -First 1))" "ERROR" }
    } catch { Write-Host "ERROR" -ForegroundColor Red; Write-Log "Exception $($app.name): $_" "ERROR" }
}

# ─── Uložit inventář ──────────────────────────────────────────
$invDir = Split-Path $invPath -Parent
if (-not (Test-Path $invDir)) { New-Item -Path $invDir -ItemType Directory -Force | Out-Null }
$Inventory | ConvertTo-Json -Depth 3 | Out-File $invPath -Encoding UTF8
Write-Log "Inventory saved: $invPath" "INFO"

Write-Host ""
Write-Host "✅ $ok z $($installQueue.Count) nainstalováno" -ForegroundColor Green
Write-Host "  📝  Log: $logFile" -ForegroundColor DarkGray
Write-Log "20-install-software complete: $ok/$($installQueue.Count)" "INFO"
exit $(if ($ok -eq $installQueue.Count) { 0 } else { 1 })
