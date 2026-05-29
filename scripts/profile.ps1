#!/usr/bin/env pwsh
# === scripts/profile.ps1 ======================================
# ROLE:   Detect active profile (home / work / lab)
#         Detekce aktivního profilu
# INPUT:  profiles/*.json  +  env detection
# OUTPUT: $ProfileName, $ProfileData  +  uloží do ~/.dev-env/config/
# ==============================================================
param([switch]$Force, [string]$Set)

$profilesDir = Join-Path $PSScriptRoot ".." "profiles"
$configDir   = Join-Path $env:USERPROFILE ".dev-env" "config"

# 1. Load profiles / načíst profily
$profiles = @{}
Get-ChildItem "$profilesDir/*.json" | ForEach-Object {
    try { $profiles[$_.BaseName] = Get-Content $_.FullName -Raw | ConvertFrom-Json }
    catch { Write-Host "  WARN: cannot parse $($_.Name)" -ForegroundColor Yellow }
}

# 2. Manual override / ruční přepsání
if ($Set -and $profiles[$Set]) {
    $ProfileName = $Set
    Write-Host ">>> PROFILE: $ProfileName (manual override)" -ForegroundColor Cyan
} elseif (Test-Path "$configDir/profile.json") {
    $ProfileName = (Get-Content "$configDir/profile.json" -Raw | ConvertFrom-Json).profile
    Write-Host ">>> PROFILE: $ProfileName (saved)" -ForegroundColor Cyan
} else {
    # 3. Auto-detect / automatická detekce
    $domain = $env:USERDOMAIN
    $proxy  = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue).ProxyServer
    $cs     = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue

    # Firemní signály
    if ($cs.PartOfDomain -and $domain -ne "WORKGROUP") {
        $ProfileName = "work"
    }
    # VM detekce (lab)
    elseif ($cs.Manufacturer -match "VMware|VirtualBox|QEMU|Xen") {
        $ProfileName = "lab"
    }
    # Firemní proxy bez domény (VPN?)
    elseif ($proxy) {
        $ProfileName = "work"
    }
    # Vše ostatní = home
    else {
        $ProfileName = "home"
    }
    Write-Host ">>> PROFILE: $ProfileName (auto-detected)" -ForegroundColor Cyan
}

# 4. Resolve inheritance / sloučit base + profil
#    Shallow merge: base values + profile overrides
$ProfileData = $profiles["base"].PSObject.Copy()
if ($profiles[$ProfileName] -and $ProfileName -ne "base") {
    $override = $profiles[$ProfileName]
    $override.PSObject.Properties | ForEach-Object {
        # Override top-level keys; deeper nesting kept from base
        Add-Member -InputObject $ProfileData -MemberType NoteProperty -Name $_.Name -Value $_.Value -Force
    }
}

# 5. Save / uložit
$null = New-Item -ItemType Directory -Path $configDir -Force
@{ profile = $ProfileName; detectedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss") } | ConvertTo-Json | Set-Content "$configDir/profile.json" -Encoding UTF8

# 6. Output summary / shrnutí
Write-Host "  Identity : $($ProfileData.identity.git.email)" -ForegroundColor Yellow
Write-Host "  Proxy    : $($ProfileData.proxy ?? 'none')" -ForegroundColor Yellow
Write-Host "  Package  : $($ProfileData.packageManager ?? 'manual')" -ForegroundColor Yellow
if ($ProfileData.restrictions) {
    Write-Host "  ⚠ RESTRICTED MODE" -ForegroundColor Red
    $ProfileData.restrictions.PSObject.Properties | ForEach-Object {
        Write-Host "    $($_.Name): $($_.Value)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "  Use / Pouzij:  scripts/setup-$ProfileName.ps1 -WhatIf" -ForegroundColor Cyan
