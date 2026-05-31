#!/usr/bin/env pwsh
# === scripts/90-wt-profile.ps1 ================================
# ROLE:   Add DevEnv profile to Windows Terminal
#         Přidá profil DevEnv do Windows Terminal
# RUN:    ./90-wt-profile.ps1             (zobrazí náhled)
#         ./90-wt-profile.ps1 -Force      (aplikuje)
# ==============================================================
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Force)

$wtDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
$wtSettingsPath = Join-Path $wtDir "settings.json"

if (-not (Test-Path $wtSettingsPath)) {
    Write-Host "❌ Windows Terminal settings not found" -ForegroundColor Red
    Write-Host "   Install Windows Terminal first: winget install Microsoft.WindowsTerminal" -ForegroundColor Cyan
    exit 1
}

Write-Host "📂 Windows Terminal: $wtSettingsPath" -ForegroundColor DarkGray

# Načíst aktuální nastavení
try {
    $wtSettings = Get-Content $wtSettingsPath -Raw | ConvertFrom-Json
} catch {
    Write-Host "❌ Cannot parse Windows Terminal settings" -ForegroundColor Red; exit 1
}

# Definice nového profilu
$profileGuid = "{db1b5e3a-8c5e-4a7c-9f2c-5c6b7a8d9e0f}"
$wtIcon = "https://raw.githubusercontent.com/doma77git/dev-env/master/docs/icon.png"

$newProfile = [ordered]@{
    name            = "DevEnv"
    commandline     = "pwsh.exe -NoExit -Command `"cd ~/.dev-env/repo; .\scripts\00-menu.ps1`""
    startingDirectory = "$env:USERPROFILE\.dev-env\repo"
    icon            = $wtIcon
    guid            = $profileGuid
    hidden          = $false
    font            = [ordered]@{ face = "Cascadia Code PL"; size = 11 }
    colorScheme     = "Campbell"
    cursorShape     = "filledBox"
}

# Zkontrolovat, zda už profil existuje
$existing = $wtSettings.profiles.list | Where-Object { $_.guid -eq $profileGuid -or $_.name -eq "DevEnv" }
if ($existing) {
    Write-Host "  ℹ️  Profil DevEnv již existuje" -ForegroundColor Yellow
    if (-not $Force) { Write-Host "      Pro přepsání použij -Force" -ForegroundColor DarkGray; exit 0 }
    $wtSettings.profiles.list = $wtSettings.profiles.list | Where-Object { $_ -ne $existing }
}

# Přidat profil
$wtSettings.profiles.list += $newProfile

# Uložit
if ($PSCmdlet.ShouldProcess("$wtSettingsPath", "Add DevEnv profile to Windows Terminal")) {
    $wtSettings | ConvertTo-Json -Depth 10 | Out-File $wtSettingsPath -Encoding UTF8
    Write-Host "  ✅  Profil DevEnv přidán do Windows Terminal" -ForegroundColor Green
    Write-Host "      Spuštění: DevEnv profil v roletce terminálu" -ForegroundColor Cyan
} else {
    Write-Host "  [WHATIF] Would add DevEnv profile to Windows Terminal" -ForegroundColor DarkCyan
}
