#!/usr/bin/env pwsh
# === scripts/10-detect.ps1 ====================================
# ROLE:   Environment inventory — OS, tools, PATH, OneDrive, corporate signals
#         Inventura prostředí — samostatně, bez závislosti na gitu
# RUN:    ./10-detect.ps1               (interactive)
#         ./10-detect.ps1 -WhatIf        (suchý běh — jen zobrazí, neukládá)
# ==============================================================
[CmdletBinding(SupportsShouldProcess=$false)]
param()

$ErrorActionPreference = "Continue"
$RepoUrl  = "https://github.com/doma77git/dev-env"
$envDir   = Join-Path $env:USERPROFILE ".dev-env"

# ─── Logger ─────────────────────────────────────────────────────
$logDir = Join-Path $env:USERPROFILE ".dev-env" "logs"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$detectLogFile = Join-Path $logDir "detect-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $logMsg = "[$ts] [$Level] $Message"
    Add-Content -Path $detectLogFile -Value $logMsg -Encoding UTF8
}
Write-Log "Phase 10 started" "INFO"

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  PHASE 10 — ENVIRONMENT DETECT           ║" -ForegroundColor Cyan
Write-Host "║  Inventura prostředí                     ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan

# ─── 10.1 Output dir ────────────────────────────────────────
if (-not (Test-Path $envDir)) {
    $null = New-Item -ItemType Directory -Path $envDir -Force
}

# ─── 10.2 Fingerprint — SHA256(hostname|username|domain) ─────
$hostname    = $env:COMPUTERNAME
$username    = $env:USERNAME
$domain      = $env:USERDOMAIN
$fingerprint = -join (([Security.Cryptography.SHA256]::Create().ComputeHash(
    [Text.Encoding]::UTF8.GetBytes("$hostname|$username|$domain")
)) | ForEach-Object { $_.ToString("x2") })

# ─── 10.3 Cache — minulý stav (machines.json) ────────────────
$machinesFile = Join-Path $envDir "machines.json"
$machines = @()
if (Test-Path $machinesFile) {
    try { $machines = @(Get-Content $machinesFile -Raw | ConvertFrom-Json) } catch {}
    $machines = @($machines)
}
$previous = $machines | Where-Object { $_.fingerprint -eq $fingerprint } | Select-Object -Last 1

# ─── 10.4 OS ─────────────────────────────────────────────────
$os  = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
$cs  = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
$osInfo = [ordered]@{
    caption     = $os.Caption
    build       = $os.BuildNumber
    arch        = $os.OSArchitecture
    installDate = ([DateTime]$os.InstallDate).ToString("yyyy-MM-dd")
    lastBoot    = ([DateTime]$os.LastBootUpTime).ToString("yyyy-MM-dd")
}

# ─── 10.5 Tools ──────────────────────────────────────────────
$detectTools = @("git","node","python","code","winget","docker","gh","pwsh","curl","7z","nvim","scoop","nvm")
$tools = [ordered]@{}
foreach ($t in $detectTools) {
    $cmd = Get-Command $t -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) {
        $ver = try { (& $t --version 2>&1 | Select-Object -First 1) -join ' ' } catch { "?" }
        $tools[$t] = "$ver | $($cmd.Source)"
    } else { $tools[$t] = $null }
}

# ─── 10.6 PATH analýza — 3 úrovně ────────────────────────────
Write-Host ""
Write-Host "─── PATH / cesty ─────────────────────────────────────" -ForegroundColor DarkCyan

# Helper: analyzuje jeden scope PATH
function Test-PathScope {
    param([string[]]$Entries, [string]$Label, [string]$ScopeName)
    $count = $Entries.Count
    $errors = @()
    
    Write-Host "  [$ScopeName] $Label" -ForegroundColor Cyan
    Write-Host "    Počet: $count entries" -ForegroundColor Gray
    
    # Duplicity
    $dupes = $Entries | Group-Object | Where-Object Count -gt 1
    if ($dupes) {
        foreach ($d in $dupes) {
            $errors += "DUP($ScopeName): $($d.Name)"
        }
        Write-Host "    ⚠  $($dupes.Count) duplicit: $($dupes.Name -join ', ')" -ForegroundColor Yellow
    } else {
        Write-Host "    ✅  Bez duplicit" -ForegroundColor Green
    }
    
    # Chybějící cesty
    $missing = $Entries | Where-Object {
        try { -not (Test-Path ([Environment]::ExpandEnvironmentVariables($_))) } catch { $true }
    }
    if ($missing) {
        foreach ($m in $missing) {
            $errors += "MISS($ScopeName): $m"
        }
        Write-Host "    ❌  $($missing.Count) chybí: $($missing -join '; ')" -ForegroundColor Red
    } else {
        Write-Host "    ✅  Všechny cesty existují" -ForegroundColor Green
    }
    
    return [ordered]@{ count = $count; errors = @($errors) }
}

# 10.6.1 System PATH (Machine scope)
$sysPathRaw = [Environment]::GetEnvironmentVariable("PATH", "Machine")
$sysEntries = $sysPathRaw -split ';' | Where-Object { $_ -ne '' }
$sysResult = Test-PathScope -Entries $sysEntries -Label "System PATH (Machine)" -ScopeName "SYS"

# 10.6.2 User PATH (User scope)
$usrPathRaw = [Environment]::GetEnvironmentVariable("PATH", "User")
$usrEntries = if ($usrPathRaw) { $usrPathRaw -split ';' | Where-Object { $_ -ne '' } } else { @() }
$usrResult = Test-PathScope -Entries $usrEntries -Label "User PATH" -ScopeName "USR"

# 10.6.3 Combined $env:PATH (runtime view)
$comEntries = $env:PATH -split ';' | Where-Object { $_ -ne '' }
$combinedResult = Test-PathScope -Entries $comEntries -Label "Combined `$env:PATH (System + User)" -ScopeName "COM"

# 10.6.4 Cross-scope duplicity
$inBoth = @()
foreach ($s in $sysEntries) {
    $sNorm = $s.TrimEnd('\')
    foreach ($u in $usrEntries) {
        $uNorm = $u.TrimEnd('\')
        if ($sNorm -eq $uNorm) { $inBoth += $sNorm }
    }
}
if ($inBoth.Count -gt 0) {
    Write-Host "  ⚠  $($inBoth.Count) cest je v System i User scope (cross-scope duplicita):" -ForegroundColor Yellow
    foreach ($ib in $inBoth | Select-Object -Unique) {
        Write-Host "      $ib" -ForegroundColor DarkYellow
    }
    Write-Host "      → Náprava: odebrat z User PATH, ponechat v System" -ForegroundColor DarkGray
} else {
    Write-Host "  ✅  Žádné cross-scope duplicity" -ForegroundColor Green
}

# 10.6.5 Souhrn PATH
Write-Host ""
Write-Host "  ─── SOUHRN ────────────────────────────────────────" -ForegroundColor DarkCyan
Write-Host "  System (Machine): $($sysEntries.Count) entries"
Write-Host "  User:             $($usrEntries.Count) entries"
Write-Host "  Combined (runtime): $($comEntries.Count) entries"
$totalErrors = $sysResult.errors.Count + $usrResult.errors.Count + $combinedResult.errors.Count
if ($totalErrors -gt 0) {
    Write-Host "  ⚠  $totalErrors problémů — spustit repair.ps1 -Force" -ForegroundColor Yellow
} else {
    Write-Host "  ✅  PATH je v pořádku" -ForegroundColor Green
}

# Sestavení strukturovaného výsledku
$pathResult = [ordered]@{
    system   = $sysResult
    user     = $usrResult
    combined = $combinedResult
    crossScopeDupes = @($inBoth | Select-Object -Unique)
}
$pathErrors = @()
$pathErrors += $sysResult.errors
$pathErrors += $usrResult.errors
$pathErrors += $combinedResult.errors

# ─── 10.7 OneDrive ──────────────────────────────────────────
Write-Host ""
Write-Host "─── OneDrive / cloud ─────────────────────────────────" -ForegroundColor DarkCyan

# 10.7.1 Cesta OneDrivu — z registru + proměnných prostředí
$odInfo = [ordered]@{}
$oneDrivePaths = @()

# Registry — osobní účet
foreach ($rp in @("HKCU:\Software\Microsoft\OneDrive\Accounts\Personal",
                  "HKCU:\Software\Microsoft\OneDrive\Accounts\Business1",
                  "HKCU:\Software\Microsoft\OneDrive\Accounts\Business2")) {
    if (Test-Path $rp) {
        $folder = (Get-ItemProperty $rp -ErrorAction SilentlyContinue).UserFolder
        if ($folder) {
            $accName = Split-Path $rp -Leaf
            $odInfo[$accName] = $folder
            $oneDrivePaths += $folder
        }
    }
}

# Proměnné prostředí
$odEnv = [Environment]::GetEnvironmentVariable("OneDrive", "User")
$odCommercial = [Environment]::GetEnvironmentVariable("OneDriveCommercial", "User")
if ($odEnv -and $odEnv -notin $oneDrivePaths) { $oneDrivePaths += $odEnv }
if ($odCommercial -and $odCommercial -notin $oneDrivePaths) { $oneDrivePaths += $odCommercial }

$primaryPath = $oneDrivePaths | Select-Object -First 1

if ($primaryPath) {
    Write-Host "  ✅  OneDrive: $primaryPath" -ForegroundColor Green
    # Ověření, zda je na systémovém disku
    $driveLetter = Split-Path -Qualifier $primaryPath
    if ($driveLetter -ne "C:") {
        Write-Host "  ⚠  OneDrive je na disku $driveLetter (mimo C:)" -ForegroundColor Yellow
    }
    if ($odCommercial) {
        Write-Host "  ℹ   Firemní OneDrive: $odCommercial" -ForegroundColor DarkGray
    }
} else {
    Write-Host "  ℹ   OneDrive není nastaven / není nainstalován" -ForegroundColor DarkGray
}

# 10.7.1b KFM detekce (musí být před 10.7.2 — potřebujeme $kfmDetected)
$kfmDetected = $false
$kfmRegPath = $null
foreach ($rp in @("HKCU:\Software\Microsoft\OneDrive\Accounts\Personal",
                  "HKCU:\Software\Microsoft\OneDrive\Accounts\Business1",
                  "HKCU:\Software\Microsoft\OneDrive\Accounts\Business2")) {
    if (Test-Path $rp) {
        $kfmVal = (Get-ItemProperty -Path $rp -Name "IsKFMEnabled" -ErrorAction SilentlyContinue).IsKFMEnabled
        if ($kfmVal -eq 1) { $kfmDetected = $true; $kfmRegPath = $rp; break }
    }
}

# 10.7.2 Known Folder Move — přesměrování systémových složek
# Používá [Environment]::GetFolderPath() — jediný spolehlivý zdroj na všech locale
$odRedirects = @{}
$knownFolderMap = [ordered]@{
    "Desktop"   = @{ cz = "Plocha";     api = "Desktop";    localFallback = "Desktop" }
    "Documents" = @{ cz = "Dokumenty";  api = "MyDocuments"; localFallback = "Documents" }
    "Pictures"  = @{ cz = "Obrázky";    api = "MyPictures"; localFallback = "Pictures" }
    "Music"     = @{ cz = "Hudba";      api = "MyMusic";    localFallback = "Music" }
    "Videos"    = @{ cz = "Videa";      api = "MyVideos";   localFallback = "Videos" }
}

foreach ($enName in $knownFolderMap.Keys) {
    $info = $knownFolderMap[$enName]
    $czName = $info.cz
    $resolvedPath = [Environment]::GetFolderPath($info.api)
    $expectedLocal = Join-Path $env:USERPROFILE $info.localFallback
    $redirectType = ""
    
    if ($resolvedPath -match 'OneDrive') {
        # Je v OneDrivu — zjistit typ
        $odRedirects[$czName] = $resolvedPath
        
        # Typ: registry check
        $regVal = $null
        $regKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
        if (Test-Path $regKey) {
            $regVal = (Get-ItemProperty $regKey -Name $enName -ErrorAction SilentlyContinue).$enName
        }
        
        # Typ: symlink check
        $localPath = Join-Path $env:USERPROFILE $info.localFallback
        $isSymlink = $false
        if (Test-Path $localPath) {
            $item = Get-Item $localPath -Force -ErrorAction SilentlyContinue
            if ($item.LinkType) { $isSymlink = $true }
        }
        
        $redirectType = switch ($true) {
            $kfmDetected  { "KFM" }
            $isSymlink    { "SYMLINK" }
            $regVal       { "KFM (manual)" }
            default       { "UNKNOWN" }
        }
        
        Write-Host "  ✗   $czName → OneDrive [$redirectType]" -ForegroundColor Yellow
        Write-Host "       Cesta: $resolvedPath" -ForegroundColor DarkGray
        if ($kfmDetected) {
            Write-Host "       ⚠  KFM aktivní — vypnout v OneDrive nastavení" -ForegroundColor Red
        } elseif ($isSymlink) {
            Write-Host "       🔗  Symlink — lze bezpečně odstranit" -ForegroundColor Yellow
        } else {
            Write-Host "       ℹ   Ruční přesun — lze vrátit zpět" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "  ✓   $czName → lokální ($resolvedPath)" -ForegroundColor Green
    }
}

# 10.7.2b Detailní symlink detekce pro Desktop (pokud není v OneDrivu)
$desktopLocal = Join-Path $env:USERPROFILE "Desktop"
if (-not ($odRedirects.Keys -contains "Plocha") -and (Test-Path $desktopLocal)) {
    $desktopItem = Get-Item $desktopLocal -Force -ErrorAction SilentlyContinue
    if ($desktopItem.LinkType) {
        Write-Host "  🔗  Desktop: symlink/junction → $($desktopItem.Target)" -ForegroundColor Yellow
    }
}

# 10.7.3 Velikost OneDrivu
if ($primaryPath -and (Test-Path $primaryPath)) {
    try {
        Write-Host "  📊 Měření velikosti OneDrivu ..." -NoNewline -ForegroundColor DarkGray
        $odItems = Get-ChildItem -Path $primaryPath -Recurse -ErrorAction SilentlyContinue
        $odSize = $odItems | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue
        $odCount = ($odItems | Where-Object { -not $_.PSIsContainer } | Measure-Object).Count
        $sizeInGB = [math]::Round($odSize.Sum / 1GB, 2)
        $sizeInMB = [math]::Round($odSize.Sum / 1MB, 1)
        Write-Host " hotovo" -ForegroundColor Green
        if ($sizeInGB -ge 1) {
            Write-Host "  💾  $sizeInGB GB ($odCount souborů)" -ForegroundColor Cyan
        } else {
            Write-Host "  💾  $sizeInMB MB ($odCount souborů)" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "  ⚠  Nelze změřit velikost" -ForegroundColor Yellow
    }
}

# 10.7.4 KFM (Known Folder Move) — výpis stavu (detekce již proběhla v 10.7.1b)
Write-Host ""
Write-Host "  ─── KFM analýza ──────────────────────────────────" -ForegroundColor DarkCyan

if ($kfmDetected) {
    Write-Host "  🔴  Known Folder Move: AKTIVNÍ (IsKFMEnabled=1)" -ForegroundColor Red
    Write-Host "      → OneDrive řídí umístění systémových složek" -ForegroundColor Yellow
    Write-Host "      → Registry: $kfmRegPath" -ForegroundColor DarkGray
    Write-Host "      → Vypnout: OneDrive → Nastavení → Zálohování → Spravovat zálohování" -ForegroundColor Cyan
} else {
    Write-Host "  🟢  Known Folder Move: neaktivní" -ForegroundColor Green
}

# Souhrn přesměrovaných složek
if ($odRedirects.Count -gt 0) {
    Write-Host ""
    Write-Host "  ─── PŘESMĚROVANÉ SLOŽKY ────────────────────────" -ForegroundColor DarkCyan
    $redirectedNames = $odRedirects.Keys -join ', '
    Write-Host "  ⚠  $($odRedirects.Count) složek v OneDrivu: $redirectedNames" -ForegroundColor Yellow
    $totalSize = if ($odSize) { [math]::Round($odSize.Sum / 1MB, 0) } else { "?" }
    Write-Host "  📦  Celkem ~$totalSize MB dat k přesunu" -ForegroundColor DarkGray
    if (-not $kfmDetected) {
        Write-Host "  ℹ   KFM neaktivní → lze bezpečně vrátit pomocí:" -ForegroundColor Green
        Write-Host "      .\scripts\60-repair.ps1 -Force" -ForegroundColor Cyan
    }
}

# Uložit KFM info do reportu
$kfmInfo = [ordered]@{
    isKFMEnabled = $kfmDetected
    kfmRegPath = $kfmRegPath
    redirectedCount = $odRedirects.Count
}

# ─── 10.8 Environment Variables ─────────────────────────────
Write-Host ""
Write-Host "─── Environment Variables / proměnné prostředí ───────" -ForegroundColor DarkCyan

$envVars = [ordered]@{
    "HOME"              = $env:HOME
    "USERPROFILE"       = $env:USERPROFILE
    "APPDATA"           = $env:APPDATA
    "LOCALAPPDATA"      = $env:LOCALAPPDATA
    "TEMP"              = $env:TEMP
    "TMP"               = $env:TMP
    "PSModulePath"      = $env:PSModulePath
    "OneDrive"          = [Environment]::GetEnvironmentVariable("OneDrive", "User")
    "OneDriveCommercial"= [Environment]::GetEnvironmentVariable("OneDriveCommercial", "User")
    "DOTNET_ROOT"       = $env:DOTNET_ROOT
    "EDITOR"            = $env:EDITOR
    "VISUAL"            = $env:VISUAL
}

$envInfo = [ordered]@{}
$envNote = ""

foreach ($key in $envVars.Keys) {
    $val = $envVars[$key]
    if ($val) {
        # Speciální handling pro dlouhé hodnoty
        if ($key -eq "PSModulePath" -and $val.Length -gt 80) {
            $shortVal = ($val -split ';')[0] + "; ..."
            Write-Host "  ✅  $key = $shortVal" -ForegroundColor Gray
        } else {
            Write-Host "  ✅  $key = $val" -ForegroundColor Gray
        }
        $envInfo[$key] = $val
    } else {
        Write-Host "  ℹ   $key = (nenastaveno)" -ForegroundColor DarkGray
        $envInfo[$key] = $null
    }
}

# PowerShell specifika
Write-Host ""
Write-Host "  ─── PowerShell ───────────────────────────────────" -ForegroundColor DarkCyan
Write-Host "  Verze:          $($PSVersionTable.PSVersion)" -ForegroundColor Gray
$edition = if ($PSVersionTable.PSEdition) { $PSVersionTable.PSEdition } else { "Desktop" }
Write-Host "  Edice:          $edition" -ForegroundColor Gray
Write-Host "  PROFILE:        $PROFILE" -ForegroundColor Gray
$execPolicy = Get-ExecutionPolicy -ErrorAction SilentlyContinue
Write-Host "  ExecutionPolicy: $execPolicy" -ForegroundColor Gray
Write-Host "  $($Host.Name): $($Host.Version)" -ForegroundColor Gray

$envInfo["PowerShell"] = [ordered]@{
    version = "$($PSVersionTable.PSVersion)"
    edition = $edition
    profile = "$PROFILE"
    executionPolicy = "$execPolicy"
}

# ─── 10.9 Corporate signály ─────────────────────────────────
$corp = [ordered]@{
    domainJoined = $cs.PartOfDomain
    domain       = $cs.Domain
    manufacturer = $cs.Manufacturer
    model        = $cs.Model
    proxy        = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue).ProxyServer
}

# ─── 10.10 Status ───────────────────────────────────────────
$status = "new"; $changes = @()
if ($previous) {
    $pOs = $previous.os
    if ($pOs.build -ne $osInfo.build) {
        $status = "os-changed"
        $changes += "OS build: $($pOs.build) → $($osInfo.build)"
    }
    try {
        $newToolNames = @(); $lostToolNames = @()
        $prevTools = if ($previous.tools) { $previous.tools } else { $null }
        foreach ($t in $detectTools) {
            $oldVal = try { $prevTools.$t } catch { $null }
            $newVal = $tools[$t]
            if (-not $oldVal -and -not $newVal) { continue }
            if ((-not $oldVal) -and $newVal) { $newToolNames += $t; continue }
            if ($oldVal -and (-not $newVal)) { $lostToolNames += $t; continue }
            if ($oldVal -and $newVal -and "$oldVal".Trim() -ne "$newVal".Trim()) {
                $newToolNames += "$t (changed)"
            }
        }
        if ($newToolNames -or $lostToolNames) {
            if ($status -ne "os-changed") { $status = "tools-changed" }
            if ($newToolNames)  { $changes += "New: $($newToolNames -join ', ')" }
            if ($lostToolNames) { $changes += "Gone: $($lostToolNames -join ', ')" }
        }
    } catch {
        Write-Host "  ⚠ Previous report format changed — treating as new detection" -ForegroundColor DarkYellow
        $status = "new"
    }
    if ($changes.Count -eq 0) { $status = "same" }
}

# ─── 10.11 Build report object ──────────────────────────────
$report = [ordered]@{
    pipeline = [ordered]@{
        phases    = [ordered]@{ "00"="core-check"; "10"="environment-detect"; "20"="inventory-report"; "30"="repository-clone"; "40"="profile-identity"; "50"="package-setup"; "60"="environment-repair"; "70"="validation-test" }
        completed = @("00","10")
        next      = "20"
        total     = 8
    }
    meta = [ordered]@{
        coreCheck = "1.0.0"
        at        = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        repo      = $RepoUrl
    }
    status      = $status
    fingerprint = $fingerprint
    hostname    = $hostname
    username    = $username
    domain      = $domain
    os          = $osInfo
    tools       = $tools
    path        = $pathResult
    env         = $envInfo
    onedrive    = [ordered]@{ accounts = $odInfo; redirects = $odRedirects; kfm = $kfmInfo }
    corporate   = $corp
    changes     = @($changes)
}

Write-Host ""
Write-Host "  fingerprint: $fingerprint, OS: $($osInfo.caption) build $($osInfo.build), tools: $(($tools.GetEnumerator() | Where-Object { $_.Value -ne $null } | Measure-Object).Count)/$($detectTools.Count) detected" -ForegroundColor DarkGray

# Export report as script-scoped variable for next phase (20-report.ps1)
$script:DetectReport = $report

Write-Log "Phase 10 complete" "INFO"
Write-Host "  📝  Log: $detectLogFile" -ForegroundColor DarkGray
Write-Host ""
Write-Host ">>> 10 — environment-detect OK" -ForegroundColor Green
