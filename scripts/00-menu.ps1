#!/usr/bin/env pwsh
# scripts/00-menu.ps1 - Hlavní menu s auto-countdown, stavem instalace a vysvětlivkami
# Integrováno s projektovou strukturou dev-env
# === === === === === === === === === === === === === === === === === === === === ===
[CmdletBinding(SupportsShouldProcess)]
param(
    [int]$TimeoutSeconds = 10,
    [string]$DefaultChoice = "S"
)

$ErrorActionPreference = "Stop"

# ─── Cesty (projektová struktura) ──────────────────────────────
$UserDevEnv = Join-Path $HOME ".dev-env"
$PreferencesPath = Join-Path $UserDevEnv "software-preferences.json"
$InventoryPath   = Join-Path $UserDevEnv "software-inventory.json"
$LogDir          = Join-Path $UserDevEnv "logs"
$LogFile         = Join-Path $LogDir "menu-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

if (-not (Test-Path $UserDevEnv)) { New-Item -ItemType Directory -Path $UserDevEnv -Force | Out-Null }
if (-not (Test-Path $LogDir))     { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

# ─── Logger ────────────────────────────────────────────────────
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $logMsg = "[$ts] [$Level] $Message"
    # Konzole barevně podle úrovně
    switch ($Level) {
        "ERROR" { Write-Host $logMsg -ForegroundColor Red }
        "WARN"  { Write-Host $logMsg -ForegroundColor Yellow }
        "OK"    { Write-Host $logMsg -ForegroundColor Green }
        default { Write-Host $logMsg -ForegroundColor DarkGray }
    }
    Add-Content -Path $LogFile -Value $logMsg -Encoding UTF8
}
Write-Log "Menu started, Timeout=${TimeoutSeconds}s" "INFO"

# ─── Kategorie (sladěné s 50-setup-home.ps1) ──────────────────
$Categories = [ordered]@{
    required = @{
        enabled     = $true
        emoji       = "🔴"
        color       = "Red"
        description = "Základní nástroje bez kterých bootstrap nefunguje"
        apps        = @(
            @{ name = "git";    winget = "Git.Git";                  cmd = "git";    desc = "Git version control" }
            @{ name = "pwsh";   winget = "Microsoft.PowerShell";      cmd = "pwsh";   desc = "PowerShell 7" }
            @{ name = "wt";     winget = "Microsoft.WindowsTerminal"; cmd = "wt";     desc = "Windows Terminal" }
        )
    }
    recommended = @{
        enabled     = $true
        emoji       = "🟡"
        color       = "Yellow"
        description = "Běžně používané aplikace pro každodenní práci"
        apps        = @(
            @{ name = "code";     winget = "Microsoft.VisualStudioCode"; cmd = "code";     desc = "VS Code editor" }
            @{ name = "7z";       winget = "7zip.7zip";                  cmd = "7z";       desc = "7-Zip archiver" }
            @{ name = "chrome";   winget = "Google.Chrome";              cmd = "chrome";   desc = "Chrome browser" }
            @{ name = "notepad++";winget = "Notepad++.Notepad++";        cmd = "notepad++";desc = "Notepad++ editor" }
            @{ name = "gh";       winget = "GitHub.cli";                 cmd = "gh";       desc = "GitHub CLI" }
            @{ name = "curl";     winget = "curl";                       cmd = "curl";     desc = "cURL" }
        )
    }
    optional = @{
        enabled     = $true
        emoji       = "🟢"
        color       = "Green"
        description = "Nástroje pro pokročilé uživatele a speciální použití"
        apps        = @(
            @{ name = "nvim";     winget = "Neovim.Neovim";          cmd = "nvim";     desc = "Neovim editor" }
            @{ name = "docker";   winget = "Docker.DockerDesktop";    cmd = "docker";   desc = "Docker Desktop" }
            @{ name = "starship"; winget = "Starship.Starship";       cmd = "starship"; desc = "Starship prompt" }
        )
    }
    dev = @{
        enabled     = $true
        emoji       = "🔵"
        color       = "Cyan"
        description = "Vývojové prostředí a nástroje pro programátory"
        apps        = @(
            @{ name = "node";     winget = "OpenJS.NodeJS.LTS";      cmd = "node";     desc = "Node.js" }
            @{ name = "python";   winget = "Python.Python.3.12";     cmd = "python";   desc = "Python 3.12" }
            @{ name = "vs2022";   winget = "Microsoft.VisualStudio.2022.Community"; cmd = "devenv"; desc = "Visual Studio 2022" }
            @{ name = "rider";    winget = "JetBrains.Rider";        cmd = "rider";    desc = "JetBrains Rider" }
            @{ name = "postman";  winget = "Postman.Postman";        cmd = "postman";  desc = "Postman API" }
        )
    }
}

# ─── Načtení preferencí ───────────────────────────────────────
if (Test-Path $PreferencesPath) {
    try {
        $saved = Get-Content $PreferencesPath -Raw | ConvertFrom-Json
        foreach ($key in $Categories.Keys) {
            if ($saved.$key -and $saved.$key.enabled -ne $null) {
                $Categories[$key].enabled = [bool]$saved.$key.enabled
            }
        }
        Write-Log "Preferences loaded: $PreferencesPath" "OK"
    } catch { Write-Log "Failed to load preferences: $_" "WARN" }
} else {
    # Vytvořit výchozí
    $defaultPrefs = [ordered]@{}
    foreach ($key in $Categories.Keys) { $defaultPrefs[$key] = @{ enabled = $Categories[$key].enabled } }
    $prefsDir = Split-Path $PreferencesPath -Parent
    if (-not (Test-Path $prefsDir)) { New-Item -Path $prefsDir -ItemType Directory -Force | Out-Null }
    $defaultPrefs | ConvertTo-Json -Depth 3 | Out-File $PreferencesPath -Encoding UTF8
    Write-Log "Default preferences created: $PreferencesPath" "INFO"
}

# ─── Načtení inventáře ────────────────────────────────────────
$Inventory = @{}
if (Test-Path $InventoryPath) {
    try { $Inventory = Get-Content $InventoryPath -Raw | ConvertFrom-Json } catch {}
}

# ─── Detekce nainstalovaných aplikací ─────────────────────────
function Test-AppInstalled {
    param([string]$AppName)
    
    # 1. Najít cmd z kategorie
    $catFound = $null
    foreach ($key in $Categories.Keys) {
        foreach ($a in $Categories[$key].apps) {
            if ($a.name -eq $AppName) { $catFound = $a; break }
        }
        if ($catFound) { break }
    }
    if (-not $catFound) { return $false }
    
    # 2. Get-Command (PATH)
    if (Get-Command $catFound.cmd -ErrorAction SilentlyContinue) { return $true }
    
    # 3. Fallback: známé instalační cesty (pro appky ne v PATH)
    $pf = ${env:ProgramFiles}
    $pfx86 = ${env:ProgramFiles(x86)}
    $local = ${env:LOCALAPPDATA}
    $progs = "${env:ProgramW6432}"
    
    $knownPaths = @{
        "chrome"    = @("$pfx86\Google\Chrome\Application\chrome.exe", "$pf\Google\Chrome\Application\chrome.exe", "$local\Google\Chrome\Application\chrome.exe")
        "7z"        = @("$pf\7-Zip\7z.exe", "$pfx86\7-Zip\7z.exe")
        "notepad++" = @("$pf\Notepad++\notepad++.exe", "$pfx86\Notepad++\notepad++.exe")
        "nvim"      = @("$pf\Neovim\bin\nvim.exe", "$local\Neovim\bin\nvim.exe")
        "docker"    = @("$pf\Docker\Docker\Docker Desktop.exe", "$pf\Docker\Docker\resources\bin\docker.exe")
        "starship"  = @("$pf\starship\bin\starship.exe")
        "vs2022"    = @("$pf\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe")
        "rider"     = @("$pf\JetBrains\JetBrains Rider\bin\rider64.exe", "$local\JetBrains\JetBrains Rider\bin\rider64.exe")
        "postman"   = @("$pf\Postman\Postman.exe", "$local\Postman\Postman.exe")
        "wt"        = @("$local\Microsoft\WindowsApps\wt.exe")
        "code"      = @("$pf\Microsoft VS Code\Code.exe", "$local\Programs\Microsoft VS Code\Code.exe")
        "gh"        = @("$pf\GitHub CLI\gh.exe")
    }
    
    if ($knownPaths.ContainsKey($AppName)) {
        foreach ($p in $knownPaths[$AppName]) {
            if (Test-Path $p) { return $true }
        }
    }
    
    # 4. Fallback: inventář
    if ($Inventory.$AppName -eq $true) { return $true }
    
    return $false
}

# ─── Stav kategorie ───────────────────────────────────────────
function Get-CategoryStatus {
    param($Apps)
    $installed = 0; $total = $Apps.Count
    foreach ($a in $Apps) { if (Test-AppInstalled $a.name) { $installed++ } }
    $pct = if ($total -gt 0) { [math]::Round(($installed / $total) * 100) } else { 0 }
    $bar = ("✅" * $installed) + ("☐" * ($total - $installed))
    return @{ Installed = $installed; Total = $total; StatusBar = $bar; Percent = $pct }
}

# ─── Instalace jedné aplikace ─────────────────────────────────
function Install-App {
    param($App, [string]$CategoryKey)
    if ($WhatIfPreference) { Write-Host "  ⚡  [WhatIf] Instaloval bych: $($App.name) ($($App.winget))" -ForegroundColor Cyan; return $true }
    
    $action = "Install $($App.name) ($($App.winget))"
    if (-not $PSCmdlet.ShouldProcess($action, "winget install")) { return $false }
    
    Write-Host "  📦 Instaluji $($App.name) ..." -NoNewline -ForegroundColor Cyan
    try {
        $result = winget install $App.winget --accept-package-agreements --accept-source-agreements --silent 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host " OK" -ForegroundColor Green
            Write-Log "Installed $($App.name) ($($App.winget))" "OK"
            $Inventory | Add-Member -NotePropertyName $App.name -NotePropertyValue $true -Force
            return $true
        } else {
            Write-Host " FAIL ($LASTEXITCODE)" -ForegroundColor Red
            Write-Log "Install failed $($App.name): $(($result | Select-Object -First 1))" "ERROR"
            return $false
        }
    } catch {
        Write-Host " ERROR" -ForegroundColor Red
        Write-Log "Install exception $($App.name): $_" "ERROR"
        return $false
    }
}

# ─── Vykreslení menu ──────────────────────────────────────────
function Show-Menu {
    Clear-Host
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Gray
    Write-Host "║  DEV-ENV SETUP — Výběr kategorií                              ║" -ForegroundColor Cyan
    Write-Host "║  (automatický start za ${TimeoutSeconds}s)                                   ║" -ForegroundColor DarkGray
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Gray
    Write-Host ""

    $script:categoryIndex = @()
    $idx = 1
    foreach ($key in $Categories.Keys) {
        $cat = $Categories[$key]
        if (-not $cat.enabled) { continue }
        $script:categoryIndex += $key
        $status = Get-CategoryStatus -Apps $cat.apps
        $pctColor = if ($status.Percent -eq 100) { "Green" } elseif ($status.Percent -gt 0) { "Yellow" } else { "Red" }
        $label = $key.Substring(0,1).ToUpper() + $key.Substring(1)

        Write-Host "$($cat.emoji) [$idx] $label ($($status.Total))" -NoNewline -ForegroundColor $cat.color
        Write-Host "    $($cat.description)" -ForegroundColor Gray
        Write-Host "        $($status.StatusBar)" -ForegroundColor $pctColor
        Write-Host "        $($status.Installed)/$($status.Total) ($($status.Percent)%)" -ForegroundColor DarkGray
        Write-Host ""
        $idx++
    }

    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Gray
    Write-Host "║  [S] 🚀 Spustit instalaci (automaticky za ${TimeoutSeconds}s)              ║" -ForegroundColor Green
    Write-Host "║  [R] 🔄 Obnovit stav (znovu detekovat)                         ║" -ForegroundColor Yellow
    Write-Host "║  [Q] ❌ Konec                                                  ║" -ForegroundColor Red
    Write-Host "║  [?] ℹ️  Vysvětlivky kategorii                                 ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Gray
    Write-Host "  📝  Log: $LogFile" -ForegroundColor DarkGray
    Write-Host ""
}

# ─── Vysvětlivky ──────────────────────────────────────────────
function Show-Help {
    Clear-Host
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Gray
    Write-Host "║  ℹ️  VYSVĚTLIVKY KATEGORIÍ                                   ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Gray
    Write-Host ""
    foreach ($key in $Categories.Keys) {
        $cat = $Categories[$key]
        $label = $key.Substring(0,1).ToUpper() + $key.Substring(1)
        Write-Host "$($cat.emoji) $label" -ForegroundColor $cat.color
        Write-Host "   $($cat.description)" -ForegroundColor Gray
        Write-Host "   Obsahuje:" -ForegroundColor DarkGray
        foreach ($a in $cat.apps) {
            $s = if (Test-AppInstalled $a.name) { "✅" } else { "☐" }
            Write-Host "     $s $($a.name) — $($a.desc)" -ForegroundColor Gray
        }
        Write-Host ""
    }
    Write-Host "⬅️  Návrat za 2 sekundy ..." -ForegroundColor DarkGray; Start-Sleep -Seconds 2
}

# ─── Auto-countdown ───────────────────────────────────────────
function Get-Choice {
    param([string]$Default)
    $tick = 0; $choice = $null
    Write-Host "Volba [${Default}]: " -NoNewline -ForegroundColor Yellow
    while ($tick -lt $TimeoutSeconds -and $choice -eq $null) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            $choice = $key.KeyChar.ToString().ToUpper(); break
        }
        $remaining = $TimeoutSeconds - $tick
        Write-Host "`rVolba [${Default}]: (${remaining}s) " -NoNewline -ForegroundColor Yellow
        Start-Sleep -Seconds 1; $tick++
    }
    if ($choice -eq $null) {
        $choice = $Default.ToUpper()
        Write-Host "`rVolba [${Default}]: ${choice} (automaticky)    " -ForegroundColor Green
    } else {
        Write-Host "`rVolba [${Default}]: ${choice}                    " -ForegroundColor Green
    }
    return $choice
}

# ─── Hlavní smyčka ───────────────────────────────────────────
do {
    Show-Menu
    $choice = Get-Choice -Default $DefaultChoice
    Write-Host ""

    switch ($choice) {
        "S" {
            Write-Log "User selected: Install" "INFO"
            # Získání seznamu chybějících
            $missing = @()
            foreach ($key in $Categories.Keys) {
                if (-not $Categories[$key].enabled) { continue }
                foreach ($a in $Categories[$key].apps) {
                    if (-not (Test-AppInstalled $a.name)) {
                        $missing += @{ App = $a; Category = $key }
                    }
                }
            }

            if ($missing.Count -eq 0) {
                Write-Host "✅ Všechny aplikace jsou již nainstalovány!" -ForegroundColor Green
                Write-Log "All apps already installed" "OK"
                Write-Host "Stiskněte libovolnou klávesu..."; $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                continue
            }

            Write-Host "Nalezeno $($missing.Count) aplikací k instalaci:" -ForegroundColor Cyan
            foreach ($m in $missing) {
                $c = $Categories[$m.Category].color
                Write-Host "  • $($m.App.name)" -NoNewline -ForegroundColor Gray
                Write-Host " [$($m.Category)]" -ForegroundColor $c
            }

            Write-Host ""
            Write-Host "Chcete pokračovat? [Y/N] " -NoNewline -ForegroundColor Yellow
            $confirm = (Read-Host).ToUpper()
            if ($confirm -ne "Y") { Write-Host "Instalace zrušena." -ForegroundColor Red; continue }

            $ok = 0
            foreach ($m in $missing) {
                if (Install-App -App $m.App -CategoryKey $m.Category) { $ok++ }
            }

            # Uložit inventář
            $Inventory | ConvertTo-Json -Depth 3 | Out-File $InventoryPath -Encoding UTF8
            Write-Log "Inventory saved to: $InventoryPath" "INFO"

            Write-Host "`n✅ Instalace dokončena! ($ok z $($missing.Count) OK)" -ForegroundColor Green
            Write-Host "Stiskněte libovolnou klávesu..."; $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "R" {
            Write-Host "🔄 Obnovuji stav ..." -ForegroundColor Yellow
            # Znovu detekovat vše
            foreach ($key in $Categories.Keys) {
                foreach ($a in $Categories[$key].apps) {
                    if (Get-Command $a.cmd -ErrorAction SilentlyContinue) {
                        $Inventory | Add-Member -NotePropertyName $a.name -NotePropertyValue $true -Force
                    }
                }
            }
            $Inventory | ConvertTo-Json -Depth 3 | Out-File $InventoryPath -Encoding UTF8
            Write-Host "✅ Stav obnoven!" -ForegroundColor Green; Start-Sleep -Seconds 1
        }
        "Q" { Write-Log "User exited" "INFO"; Write-Host "❌ Konec." -ForegroundColor Red; exit 0 }
        "?" { Show-Help }
        default {
            $catIndex = [int]$choice - 1
            if ($catIndex -ge 0 -and $catIndex -lt $categoryIndex.Count) {
                $key = $categoryIndex[$catIndex]
                $cat = $Categories[$key]
                $label = $key.Substring(0,1).ToUpper() + $key.Substring(1)
                Write-Host "ℹ️  $($cat.emoji) $label — $($cat.description)" -ForegroundColor $cat.color
                Write-Host "Aplikace:" -ForegroundColor Gray
                foreach ($a in $cat.apps) {
                    $s = if (Test-AppInstalled $a.name) { "✅" } else { "☐" }
                    Write-Host "  $s $($a.name) — $($a.desc)" -ForegroundColor Gray
                }
                Write-Host ""; Write-Host "Stiskněte libovolnou klávesu..."; $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            } else {
                Write-Host "❌ Neplatná volba!" -ForegroundColor Red; Start-Sleep -Seconds 1
            }
        }
    }
} while ($true)
