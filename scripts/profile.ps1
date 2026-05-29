#!/usr/bin/env pwsh
# === scripts/profile.ps1 ======================================
# ROLE:   Detect active profile (home / work / lab)
#         Detekce aktivního profilu
# INPUT:  profiles/*.json  +  env detection
# OUTPUT: $ProfileName, $ProfileData  +  uloží do ~/.dev-env/config/
# ==============================================================
param([switch]$Force, [string]$Set, [switch]$WhatIf)

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
#    Deep merge: base values + profile overrides, nested keys preserved
function Merge-Deep {
    param([PSObject]$Base, [PSObject]$Override)
    if ($null -eq $Override) { return $Base }
    $result = $Base.PSObject.Copy()
    $Override.PSObject.Properties | ForEach-Object {
        $key   = $_.Name
        $oVal  = $_.Value
        $bVal  = $result.$key
        if ($oVal -is [array] -and $bVal -is [array]) {
            # Arrays: concatenate and deduplicate
            $result.$key = ($bVal + $oVal) | Select-Object -Unique
        } elseif ($oVal -is [PSCustomObject] -and $bVal -is [PSCustomObject]) {
            # Nested objects: recurse
            $result.$key = Merge-Deep -Base $bVal -Override $oVal
        } else {
            # Primitives / null: override wins
            Add-Member -InputObject $result -MemberType NoteProperty -Name $key -Value $oVal -Force
        }
    }
    return $result
}
if ($profiles[$ProfileName] -and $ProfileName -ne "base") {
    $ProfileData = Merge-Deep -Base $profiles["base"] -Override $profiles[$ProfileName]
} else {
    $ProfileData = $profiles["base"].PSObject.Copy()
}

# 4b. Identity detection — přednost má saved > git config > profile default
#     Detekce identity — ne hardcoded placeholder
$identityFile = Join-Path $configDir "identity.json"
$savedIdentity = if (Test-Path $identityFile) {
    try { Get-Content $identityFile -Raw | ConvertFrom-Json } catch { $null }
} else { $null }

if ($savedIdentity -and $savedIdentity.git.email) {
    # Saved override wins
    $ProfileData.identity.git.name  = $savedIdentity.git.name
    $ProfileData.identity.git.email = $savedIdentity.git.email
    $identitySource = "saved"
} else {
    # Detect from git global config
    $gitName  = try { git config --global user.name  2>$null } catch { $null }
    $gitEmail = try { git config --global user.email 2>$null } catch { $null }
    if ($gitName -and $gitEmail) {
        $ProfileData.identity.git.name  = $gitName
        $ProfileData.identity.git.email = $gitEmail
        $identitySource = "git-config"
        # Auto-save for future runs
        if (-not $WhatIf) {
            $null = New-Item -ItemType Directory -Path $configDir -Force
            @{ git = @{ name = $gitName; email = $gitEmail } } | ConvertTo-Json | Set-Content $identityFile -Encoding UTF8
        }
    } else {
        $identitySource = "placeholder"
    }
}

# 5. Save / uložit
if (-not $WhatIf) {
    $null = New-Item -ItemType Directory -Path $configDir -Force
    @{ profile = $ProfileName; detectedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss") } | ConvertTo-Json | Set-Content "$configDir/profile.json" -Encoding UTF8
} else {
    Write-Host "  [WHATIF] Would save profile: $ProfileName → ~/.dev-env/config/profile.json" -ForegroundColor DarkCyan
}

# 6. Output summary / shrnutí
$identityColor = if ($identitySource -eq "placeholder") { "Red" } elseif ($identitySource -eq "git-config") { "Green" } else { "Yellow" }
Write-Host "  Identity : $($ProfileData.identity.git.email) ($identitySource)" -ForegroundColor $identityColor
if ($identitySource -eq "placeholder") {
    Write-Host "  ⚠ IDENTITY IS A PLACEHOLDER! Run: setup-$ProfileName.ps1 -Force" -ForegroundColor Red
}
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
