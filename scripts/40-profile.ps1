#!/usr/bin/env pwsh
# === scripts/40-profile.ps1 ===================================
# ROLE:   Detect active profile (home / work / lab / server)
#         Detekce aktivního profilu podle domény, OS, VM, proxy
# RUN:    ./40-profile.ps1               (auto-detect)
#         ./40-profile.ps1 -Set home     (manual override)
#         ./40-profile.ps1 -WhatIf       (suchý běh — neukládá)
# INPUT:  profiles/*.json  +  env detection (domain, OS, manufacturer, proxy)
# OUTPUT: $ProfileName, $ProfileData  +  uloží do ~/.dev-env/config/profile.json
# ==============================================================
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Force, [string]$Set)

$profilesDir = Join-Path $PSScriptRoot ".." "profiles"
$configDir   = Join-Path $env:USERPROFILE ".dev-env" "config"

# 0. System detection — always runs (needed for output + profile auto-detect)
#    Detekce systému — běží vždy
$osInfo = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
$csInfo = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
$detectedDomain = $env:USERDOMAIN
$detectedProxy  = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue).ProxyServer

# 1. Load profiles / načíst profily
$profiles = @{}
Get-ChildItem "$profilesDir/*.json" | ForEach-Object {
    try { $profiles[$_.BaseName] = Get-Content $_.FullName -Raw | ConvertFrom-Json }
    catch { Write-Host "  WARN: cannot parse $($_.Name)" -ForegroundColor Yellow }
}

# 1b. Validate profile JSON structure
$requiredKeys = @("extends", "identity", "proxy", "safeMode", "tools")
foreach ($pname in $profiles.Keys) {
    $p = $profiles[$pname]
    $issues = @()
    if ($pname -ne "base" -and -not $p.extends) { $issues += "missing 'extends'" }
    if (-not $p.identity) { $issues += "missing 'identity'" }
    elseif (-not $p.identity.git) { $issues += "missing 'identity.git'" }
    if ($p.safeMode -isnot [bool] -and $null -ne $p.safeMode) { $issues += "'safeMode' must be boolean" }
    if ($issues.Count -gt 0) {
        Write-Host "  WARN: profile '$pname' validation issues: $($issues -join ', ')" -ForegroundColor Yellow
    }
}

# 2. Manual override / ruční přepsání
if ($Set -and $profiles[$Set]) {
    $ProfileName = $Set
    Write-Host ">>> PHASE 40 — PROFILE & IDENTITY: $ProfileName (manual override)" -ForegroundColor Cyan
} elseif (Test-Path "$configDir/profile.json") {
    $ProfileName = (Get-Content "$configDir/profile.json" -Raw | ConvertFrom-Json).profile
    Write-Host ">>> PHASE 40 — PROFILE & IDENTITY: $ProfileName (saved)" -ForegroundColor Cyan
} else {
    # 3. Auto-detect / automatická detekce
    # Firemní signály
    $detectReason = ""
    if ($csInfo.PartOfDomain -and $detectedDomain -ne "WORKGROUP") {
        $ProfileName = "work"
        $detectReason = "domain-joined: $detectedDomain"
    }
    # VM detekce (lab)
    elseif ($csInfo.Manufacturer -match "VMware|VirtualBox|QEMU|Xen") {
        $ProfileName = "lab"
        $detectReason = "VM detected: $($csInfo.Manufacturer) $($csInfo.Model)"
    }
    # Firemní proxy bez domény (VPN?)
    elseif ($detectedProxy) {
        $ProfileName = "work"
        $detectReason = "corporate proxy: $detectedProxy"
    }
    # Server detection (headless OS)
    elseif ($osInfo.Caption -match "Server") {
        $ProfileName = "server"
        $detectReason = "server OS: $($osInfo.Caption)"
    }
    # Vše ostatní = home
    else {
        $ProfileName = "home"
        $detectReason = "no domain, no proxy, no VM"
    }
    Write-Host ">>> PHASE 40 — PROFILE & IDENTITY: $ProfileName (auto-detected)" -ForegroundColor Cyan
    Write-Host "  Reason   : $detectReason" -ForegroundColor DarkGray
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
    try {
        $ProfileData = Merge-Deep -Base $profiles["base"] -Override $profiles[$ProfileName]
    } catch {
        Write-Host "  ⚠ Merge failed, using base profile: $_" -ForegroundColor Yellow
        $ProfileData = if ($profiles["base"]) { $profiles["base"].PSObject.Copy() } else { $null }
    }
} elseif ($profiles["base"]) {
    $ProfileData = $profiles["base"].PSObject.Copy()
} else {
    Write-Host "  ❌ No base profile found" -ForegroundColor Red
    $ProfileData = [pscustomobject]@{ identity = [pscustomobject]@{ git = [pscustomobject]@{ name = "User"; email = "user@localhost" } }; safeMode = $false }
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
        if (-not $WhatIfPreference) {
            $null = New-Item -ItemType Directory -Path $configDir -Force
            @{ git = @{ name = $gitName; email = $gitEmail } } | ConvertTo-Json | Set-Content $identityFile -Encoding UTF8
        }
    } else {
        $identitySource = "placeholder"
    }
}

# 5. Save / uložit
if (-not $WhatIfPreference) {
    $null = New-Item -ItemType Directory -Path $configDir -Force
    $now = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    @{ profile = $ProfileName; detectedAt = $now } | ConvertTo-Json | Set-Content "$configDir/profile.json" -Encoding UTF8
    
    # History append
    $historyPath = Join-Path $configDir "profile-history.json"
    $history = if (Test-Path $historyPath) { try { Get-Content $historyPath -Raw | ConvertFrom-Json } catch { @() } } else { @() }
    if ($history -isnot [array]) { $history = @($history) }
    $history += @{ timestamp = $now; profile = $ProfileName; source = $identitySource; hostname = $env:COMPUTERNAME }
    $history | ConvertTo-Json -Depth 4 | Out-File $historyPath -Encoding UTF8
} else {
    Write-Host "  [WHATIF] Would save profile: $ProfileName → ~/.dev-env/config/profile.json" -ForegroundColor DarkCyan
}

# 6. Output — 3 sections: SYSTEM / USER / IDENTITIES
#     Výstup — systém, uživatel, identity
$profileIcon = @{ "home"="🏠"; "work"="🏢"; "lab"="🧪"; "server"="🖳" }
$profileLabel = @{ "home"="HOME — personal PC"; "work"="CORP — corporate PC"; "lab"="LAB — test VM"; "server"="SERVER — headless" }
$profileColor = @{ "home"="Green"; "work"="Yellow"; "lab"="Magenta"; "server"="DarkCyan" }

Write-Host ""
Write-Host "  4.1 ── SYSTEM ──────────────────────────────────" -ForegroundColor DarkCyan
Write-Host "  OS       : $($osInfo.Caption) (build $($osInfo.BuildNumber))" -ForegroundColor Gray
Write-Host "  Hostname : $env:COMPUTERNAME" -ForegroundColor Gray
$domainLabel = if ($csInfo.PartOfDomain) { "$($csInfo.Domain) (domain-joined)" } else { "$($csInfo.Domain) (workgroup)" }
Write-Host "  Domain   : $domainLabel" -ForegroundColor Gray
Write-Host "  Profile  : $($profileIcon[$ProfileName]) $($profileLabel[$ProfileName])" -ForegroundColor $profileColor[$ProfileName]
if ($detectReason) { Write-Host "  Reason   : $detectReason" -ForegroundColor DarkGray }
if ($ProfileData.restrictions) {
    Write-Host "  ⚠ RESTRICTED MODE" -ForegroundColor Red
    $ProfileData.restrictions.PSObject.Properties | ForEach-Object {
        Write-Host "    $($_.Name): $($_.Value)" -ForegroundColor Red
    }
}

Write-Host "  4.2 ── USER ────────────────────────────────────" -ForegroundColor DarkCyan
$whoami = "$env:USERDOMAIN\$env:USERNAME"
Write-Host "  Account  : $whoami" -ForegroundColor Gray
if ($csInfo.PartOfDomain) {
    Write-Host "  Type     : Domain account ($($csInfo.Domain))" -ForegroundColor Yellow
} else {
    Write-Host "  Type     : Local account" -ForegroundColor Gray
}

Write-Host "  4.3 ── IDENTITIES ──────────────────────────────" -ForegroundColor DarkCyan
$identityColor = if ($identitySource -eq "placeholder") { "Red" } elseif ($identitySource -eq "git-config") { "Green" } else { "Yellow" }
$gitLabel = if ($identitySource -eq "placeholder") { "$($ProfileData.identity.git.email) ⚠ PLACEHOLDER" } else { "$($ProfileData.identity.git.name) <$($ProfileData.identity.git.email)>" }
Write-Host "  Git      : $gitLabel ($identitySource)" -ForegroundColor $identityColor
if ($identitySource -eq "placeholder") {
    Write-Host "           ⚠ Run: 50-setup-$ProfileName.ps1 -Force" -ForegroundColor Red
}
# GitHub
$ghOutput = try { gh auth status 2>&1 | Out-String } catch { $null }
if ($ghOutput -match 'Logged in to github\.com (?:as|account)\s+(\S+)') {
    $ghAccount = $Matches[1]
    Write-Host "  GitHub   : $ghAccount (logged in)" -ForegroundColor Green
} elseif ($ghOutput -match 'not logged in') {
    Write-Host "  GitHub   : not logged in" -ForegroundColor Yellow
} else {
    Write-Host "  GitHub   : unknown (gh not available)" -ForegroundColor DarkGray
}
# SSH keys
$sshKeys = @(Get-ChildItem "$env:USERPROFILE\.ssh\id_*" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^id_' -and $_.Name -notmatch '\.pub$' })
if ($sshKeys.Count -gt 0) {
    $keyTypes = ($sshKeys | ForEach-Object { ($_.Name -replace '^id_','') }) -join ', '
    Write-Host "  SSH keys : $($sshKeys.Count) ($keyTypes)" -ForegroundColor Green
} else {
    Write-Host "  SSH keys : none" -ForegroundColor Yellow
}
# GPG signing (corporate profiles)
if ($ProfileName -eq "work" -or $ProfileName -eq "server") {
    $gpgKey = try { git config --global user.signingkey 2>$null } catch { $null }
    if ($gpgKey) {
        Write-Host "  GPG sign : $gpgKey ✅" -ForegroundColor Green
    } else {
        Write-Host "  GPG sign : not configured ⚠" -ForegroundColor Yellow
        Write-Host "           ℹ Run: git config --global user.signingkey <KEY>" -ForegroundColor DarkGray
        Write-Host "           ℹ Run: git config --global commit.gpgsign true" -ForegroundColor DarkGray
    }
}

Write-Host "  4.4 ── TOOLS ───────────────────────────────────" -ForegroundColor DarkCyan
Write-Host "  Proxy    : $($ProfileData.proxy ?? 'none')" -ForegroundColor Gray
Write-Host "  Package  : $($ProfileData.packageManager ?? 'manual')" -ForegroundColor Gray

Write-Host ""
Write-Host ">>> 40 — profile-identity OK" -ForegroundColor Green
Write-Host "  profile: $ProfileName, identity: $identitySource, proceeding with phase 40" -ForegroundColor DarkGray

Write-Host "  Use / Pouzij:  scripts/50-setup-$ProfileName.ps1 -WhatIf" -ForegroundColor Cyan
