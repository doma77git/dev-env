#!/usr/bin/env pwsh
# === scripts/00-menu.ps1 =======================================
# ROLE:   Interactive category selection for software setup
#         Interaktivní výběr kategorií pro instalaci
# RUN:    ./00-menu.ps1              (interactive mode)
#         ./00-menu.ps1 -Quick       (použít uložené preference)
# ==============================================================
[CmdletBinding(SupportsShouldProcess=$false)]
param([switch]$Quick)

$prefFile = Join-Path $env:USERPROFILE ".dev-env" "software-preferences.json"
$setupScript = Join-Path $PSScriptRoot "50-setup-home.ps1"

# Načtení uložených preferencí
$prefs = [pscustomobject]@{ categories = [pscustomobject]@{ required=$true; recommended=$true; optional=$false; dev=$false } }
if (Test-Path $prefFile) {
    try { $prefs = Get-Content $prefFile -Raw | ConvertFrom-Json } catch {}
}

# Quick mód: rovnou spustit setup s uloženými preferencemi
if ($Quick) {
    $args = @()
    if ($prefs.categories.required)    { $args += "-IncludeRequired" }
    if ($prefs.categories.recommended) { $args += "-IncludeRecommended" }
    if ($prefs.categories.optional)    { $args += "-IncludeOptional" }
    if ($prefs.categories.dev)         { $args += "-IncludeDev" }
    Write-Host "  ⚡  Quick mode: spouštím setup s uloženými preferencemi" -ForegroundColor Cyan
    & $setupScript @args
    exit $LASTEXITCODE
}

# Interaktivní menu
Clear-Host
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  SETUP — Výběr kategorií instalace       ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

function Show-Menu {
    param([pscustomobject]$Current)
    $c = $Current.categories
    Clear-Host
    Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  SETUP — Výběr kategorií                ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] 🔴  Nutné ................ $(if($c.required){'✅'}else{'☐'})" -ForegroundColor Red
    Write-Host "  [2] 🟡  Doporučené ........... $(if($c.recommended){'✅'}else{'☐'})" -ForegroundColor Yellow
    Write-Host "  [3] 🟢  Nepovinné ............ $(if($c.optional){'✅'}else{'☐'})" -ForegroundColor Green
    Write-Host "  [4] 🔵  Vývojářské ........... $(if($c.dev){'✅'}else{'☐'})" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [S] 🚀  Spustit instalaci" -ForegroundColor Green
    Write-Host "  [Q] ❌  Konec" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Aktuální výběr: " -NoNewline
    $selected = @()
    if ($c.required)    { $selected += "🔴REQ" }
    if ($c.recommended) { $selected += "🟡REC" }
    if ($c.optional)    { $selected += "🟢OPT" }
    if ($c.dev)         { $selected += "🔵DEV" }
    Write-Host "$($selected -join ' ')" -ForegroundColor White
    Write-Host ""
}

do {
    Show-Menu $prefs
    $choice = (Read-Host "  Volba").ToUpper()
    
    switch ($choice) {
        "1" { $prefs.categories.required = -not $prefs.categories.required }
        "2" { $prefs.categories.recommended = -not $prefs.categories.recommended }
        "3" { $prefs.categories.optional = -not $prefs.categories.optional }
        "4" { $prefs.categories.dev = -not $prefs.categories.dev }
        "S" {
            # Uložit preference
            $prefsDir = Split-Path $prefFile -Parent
            if (-not (Test-Path $prefsDir)) { New-Item -Path $prefsDir -ItemType Directory -Force | Out-Null }
            $prefs | ConvertTo-Json -Depth 3 | Out-File $prefFile -Encoding UTF8
            Write-Host "  💾  Preference uloženy" -ForegroundColor Green
            
            # Spustit setup
            $args = @()
            if ($prefs.categories.required)    { $args += "-IncludeRequired" }
            if ($prefs.categories.recommended) { $args += "-IncludeRecommended" }
            if ($prefs.categories.optional)    { $args += "-IncludeOptional" }
            if ($prefs.categories.dev)         { $args += "-IncludeDev" }
            
            Write-Host "  🚀  Spouštím setup ..." -ForegroundColor Cyan
            & $setupScript @args
            exit $LASTEXITCODE
        }
        "Q" { Write-Host "  Konec"; exit 0 }
    }
} while ($choice -ne "Q")
