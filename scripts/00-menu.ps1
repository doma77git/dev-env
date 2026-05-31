#!/usr/bin/env pwsh
# scripts/00-menu.ps1 - Hlavní menu s auto-countdown, stavem instalace a vysvětlivkami
# === === === === === === === === === === === === === === === === === === === === ===
param(
    [int]$TimeoutSeconds = 10,
    [string]$DefaultChoice = "S"
)

$ErrorActionPreference = "Stop"

# ─── Cesty ─────────────────────────────────────────────────────
$prefFile = Join-Path $env:USERPROFILE ".dev-env" "software-preferences.json"
$stateDir = Join-Path $env:USERPROFILE ".dev-env"
$logDir   = Join-Path $stateDir "logs"
$setupScript = Join-Path $PSScriptRoot "50-setup-home.ps1"

if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$logFile = Join-Path $logDir "menu-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
function Write-Log { param([string]$M, [string]$L="INFO"); Add-Content -Path $logFile -Value "[$(Get-Date -Format 'HH:mm:ss')] [$L] $M" -Encoding UTF8 }

# ─── Kategorie (sladěné s 10-detect.ps1 a 50-setup-home.ps1) ──
$Categories = @(
    @{
        Name = "NUTNÉ"
        Key  = "required"
        Emoji = "🔴"
        Color = "Red"
        Description = "Základní nástroje bez kterých bootstrap nefunguje"
        Apps = @(
            @{ name = "git";    winget = "Git.Git";                  desc = "Git version control" }
            @{ name = "pwsh";   winget = "Microsoft.PowerShell";      desc = "PowerShell 7" }
            @{ name = "wt";     winget = "Microsoft.WindowsTerminal"; desc = "Windows Terminal" }
        )
    }
    @{
        Name = "DOPORUČENÉ"
        Key  = "recommended"
        Emoji = "🟡"
        Color = "Yellow"
        Description = "Běžně používané aplikace pro každodenní práci"
        Apps = @(
            @{ name = "code";     winget = "Microsoft.VisualStudioCode"; desc = "VS Code editor" }
            @{ name = "7z";       winget = "7zip.7zip";                  desc = "7-Zip archiver" }
            @{ name = "chrome";   winget = "Google.Chrome";              desc = "Chrome browser" }
            @{ name = "notepad++";winget = "Notepad++.Notepad++";        desc = "Notepad++ editor" }
            @{ name = "gh";       winget = "GitHub.cli";                 desc = "GitHub CLI" }
            @{ name = "curl";     winget = "curl";                       desc = "cURL" }
        )
    }
    @{
        Name = "NEPOVINNÉ"
        Key  = "optional"
        Emoji = "🟢"
        Color = "Green"
        Description = "Nástroje pro pokročilé uživatele a speciální použití"
        Apps = @(
            @{ name = "nvim";     winget = "Neovim.Neovim";          desc = "Neovim editor" }
            @{ name = "docker";   winget = "Docker.DockerDesktop";    desc = "Docker Desktop" }
            @{ name = "starship"; winget = "Starship.Starship";       desc = "Starship prompt" }
        )
    }
    @{
        Name = "VÝVOJÁŘSKÉ"
        Key  = "dev"
        Emoji = "🔵"
        Color = "Cyan"
        Description = "Vývojové prostředí a nástroje pro programátory"
        Apps = @(
            @{ name = "node";     winget = "OpenJS.NodeJS.LTS";      desc = "Node.js" }
            @{ name = "python";   winget = "Python.Python.3.12";     desc = "Python 3.12" }
            @{ name = "vs2022";   winget = "Microsoft.VisualStudio.2022.Community"; desc = "Visual Studio 2022 Community" }
            @{ name = "rider";    winget = "JetBrains.Rider";        desc = "JetBrains Rider" }
            @{ name = "postman";  winget = "Postman.Postman";        desc = "Postman API" }
        )
    }
)

# ─── Detekce nainstalovaných (Get-Command) ────────────────────
function Get-CategoryStatus {
    param($CategoryName, $Apps)
    $installed = 0; $total = $Apps.Count
    $statusBars = ""
    foreach ($app in $Apps) {
        $isInstalled = $null -ne (Get-Command $app.name -ErrorAction SilentlyContinue)
        if ($isInstalled) { $installed++; $statusBars += "✅" } else { $statusBars += "☐" }
    }
    $pct = if ($total -gt 0) { [math]::Round(($installed / $total) * 100) } else { 0 }
    return @{ Installed = $installed; Total = $total; StatusBar = $statusBars; Percent = $pct }
}

# ─── Render menu ──────────────────────────────────────────────
function Show-Menu {
    Clear-Host
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Gray
    Write-Host "║  SETUP — Výběr kategorií instalace                           ║" -ForegroundColor Cyan
    Write-Host "║  (automatický start za ${TimeoutSeconds}s)                    ║" -ForegroundColor DarkGray
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Gray
    Write-Host ""

    foreach ($cat in $Categories) {
        $status = Get-CategoryStatus -CategoryName $cat.Name -Apps $cat.Apps
        $pctColor = if ($status.Percent -eq 100) { "Green" } elseif ($status.Percent -gt 0) { "Yellow" } else { "Red" }
        $idx = $Categories.IndexOf($cat) + 1

        Write-Host "$($cat.Emoji) [$idx] $($cat.Name) ($($status.Total))" -NoNewline -ForegroundColor $cat.Color
        Write-Host "    $($cat.Description)" -ForegroundColor Gray
        Write-Host "        $($status.StatusBar)" -ForegroundColor $pctColor
        Write-Host "        $($status.Installed)/$($status.Total) ($($status.Percent)%)" -ForegroundColor DarkGray
        Write-Host ""
    }

    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Gray
    Write-Host "║  [S] 🚀 Spustit (automaticky za ${TimeoutSeconds}s)                     ║" -ForegroundColor Green
    Write-Host "║  [Q] ❌ Konec                                                 ║" -ForegroundColor Red
    Write-Host "║  [?] ℹ️  Vysvětlivky kategorií                                 ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Gray
    Write-Host ""
}

# ─── Vysvětlivky ──────────────────────────────────────────────
function Show-Help {
    Clear-Host
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Gray
    Write-Host "║  ℹ️  VYSVĚTLIVKY KATEGORIÍ                                   ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Gray
    Write-Host ""
    foreach ($cat in $Categories) {
        Write-Host "$($cat.Emoji) $($cat.Name)" -ForegroundColor $cat.Color
        Write-Host "   $($cat.Description)" -ForegroundColor Gray
        Write-Host "   Obsahuje:" -ForegroundColor DarkGray
        foreach ($app in $cat.Apps) {
            $status = if (Get-Command $app.name -ErrorAction SilentlyContinue) { "✅" } else { "☐" }
            Write-Host "     $status $($app.name) — $($app.desc)" -ForegroundColor Gray
        }
        Write-Host ""
    }
    Write-Host "Stiskněte libovolnou klávesu pro návrat..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ─── Auto-countdown timer ────────────────────────────────────
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

Write-Log "Menu spuštěno, Timeout=${TimeoutSeconds}s" "INFO"

# ─── Hlavní smyčka ───────────────────────────────────────────
do {
    Show-Menu
    $choice = Get-Choice -Default $DefaultChoice
    Write-Host ""

    switch ($choice) {
        "S" {
            Write-Log "Uživatel zvolil: Spustit" "INFO"
            Write-Host "🚀 Spouštím instalaci..." -ForegroundColor Green
            
            # Zjistit chybějící
            $missing = @()
            foreach ($cat in $Categories) {
                foreach ($app in $cat.Apps) {
                    if (-not (Get-Command $app.name -ErrorAction SilentlyContinue)) {
                        $missing += @{ Name = $app.name; WingetId = $app.winget; Category = $cat.Key }
                    }
                }
            }
            
            if ($missing.Count -eq 0) {
                Write-Host "✅ Všechny aplikace jsou již nainstalovány!" -ForegroundColor Green
                Write-Log "Všechny aplikace již nainstalovány" "INFO"
                Write-Host "Stiskněte libovolnou klávesu..."; $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                continue
            }
            
            Write-Host "Nalezeno $($missing.Count) chybějících aplikací:" -ForegroundColor Cyan
            foreach ($a in $missing) { Write-Host "  • $($a.Name) [$($a.Category)]" -ForegroundColor Gray }
            Write-Host ""
            Write-Host "Chcete pokračovat? [Y/N] " -NoNewline -ForegroundColor Yellow
            $confirm = (Read-Host).ToUpper()
            if ($confirm -ne "Y") { Write-Host "Instalace zrušena." -ForegroundColor Red; continue }
            
            foreach ($a in $missing) {
                Write-Host "`n📦 Instaluji $($a.Name) ($($a.WingetId))..." -ForegroundColor Cyan
                try {
                    $result = winget install $a.WingetId --accept-package-agreements --accept-source-agreements --silent 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  ✅ $($a.Name) OK" -ForegroundColor Green
                        Write-Log "Installed $($a.Name) ($($a.WingetId))" "INFO"
                    } else {
                        Write-Host "  ❌ $($a.Name) FAIL (code $LASTEXITCODE)" -ForegroundColor Red
                        Write-Log "Install failed $($a.Name): $result" "ERROR"
                    }
                } catch {
                    Write-Host "  ❌ $($a.Name) ERROR: $_" -ForegroundColor Red
                    Write-Log "Install exception $($a.Name): $_" "ERROR"
                }
            }
            
            Write-Host "`n✅ Instalace dokončena!" -ForegroundColor Green
            Write-Host "  📝  Log: $logFile" -ForegroundColor DarkGray
            Write-Host "Stiskněte libovolnou klávesu..."; $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        "Q" { Write-Log "Uživatel ukončil menu" "INFO"; Write-Host "❌ Konec." -ForegroundColor Red; exit 0 }
        "?" { Show-Help }
        default {
            if ([int]::TryParse($choice, [ref]$null) -and $choice -ge 1 -and $choice -le $Categories.Count) {
                $cat = $Categories[$choice - 1]
                Write-Host "ℹ️  $($cat.Emoji) $($cat.Name) — $($cat.Description)" -ForegroundColor $cat.Color
                Write-Host "Aplikace:" -ForegroundColor Gray
                foreach ($app in $cat.Apps) {
                    $s = if (Get-Command $app.name -ErrorAction SilentlyContinue) { "✅" } else { "☐" }
                    Write-Host "  $s $($app.name) — $($app.desc)" -ForegroundColor Gray
                }
                Write-Host ""; Write-Host "Stiskněte libovolnou klávesu..."; $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            } else {
                Write-Host "❌ Neplatná volba!" -ForegroundColor Red; Start-Sleep -Seconds 1
            }
        }
    }
} while ($true)
