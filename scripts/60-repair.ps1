#!/usr/bin/env pwsh
# === scripts/60-repair.ps1 ====================================
# ROLE:   Repair common issues — PATH, HOME, OneDrive
#         Oprava běžných problémů
# RUN:    ./60-repair.ps1 -WhatIf      (dry run / suchý běh)
#         ./60-repair.ps1 -Force       (apply / aplikovat)
#         ./60-repair.ps1 -Confirm     (potvrzovat každou změnu)
# ==============================================================
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Force,
    [switch]$SkipBackup   # Přeskočí Backup-Configuration (pro testování)
)

Write-Host ">>> PHASE 60 — ENVIRONMENT REPAIR / OPRAVY" -ForegroundColor Green
Write-Host "  🔐  KFM safety: $(if(-not $Force){'ACTIVE (vyžaduje -Force pro KFM opravy)'}else{'VYPNUTO (Force mód)'})" -ForegroundColor DarkGray
if ($SkipBackup) { Write-Host "  💾  Backup: SKIP (testovací mód)" -ForegroundColor DarkGray }

# ─── Logger ─────────────────────────────────────────────────────
$logDir = Join-Path $env:USERPROFILE ".dev-env" "logs"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$logFile = Join-Path $logDir "repair-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
Add-Content -Path $logFile -Value "# repair log started $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Encoding UTF8

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $logMsg = "[$ts] [$Level] $Message"
    switch ($Level) {
        "ERROR" { Write-Host $logMsg -ForegroundColor Red }
        "WARN"  { Write-Host $logMsg -ForegroundColor Yellow }
        "DEBUG" { Write-Host $logMsg -ForegroundColor DarkGray }
        default { Write-Host $logMsg -ForegroundColor Gray }
    }
    Add-Content -Path $logFile -Value $logMsg -Encoding UTF8
}
Write-Log "Phase 60 started, Force=$Force SkipBackup=$SkipBackup" "INFO"

# ─── Invoke-EnvironmentRepair ────────────────────────────────
# Wrapper: provede opravu, při selhání automatický rollback z backupu
function Invoke-EnvironmentRepair {
    param(
        [scriptblock]$RepairAction,
        [string]$ActionName,
        [string]$BackupPath,
        [scriptblock]$VerifyAction
    )
    
    Write-Host "  🔧  $ActionName ..." -NoNewline -ForegroundColor Cyan
    try {
        & $RepairAction
        
        # Volitelné ověření úspěchu
        if ($VerifyAction) {
            $success = & $VerifyAction
            if (-not $success) { throw "Verification failed after $ActionName" }
        }
        
        Write-Host " OK" -ForegroundColor Green
        return $true
    } catch {
        Write-Host " FAIL" -ForegroundColor Red
        Write-Log "$ActionName selhalo: $_" "ERROR"
        Write-Host "  🔄  Spouštím automatický rollback ..." -ForegroundColor Yellow
        
        if ($BackupPath -and (Test-Path $BackupPath)) {
            $restoreScript = Join-Path $BackupPath "RESTORE.ps1"
            if (Test-Path $restoreScript) {
                Write-Host "  🔄  Rollback ..." -NoNewline -ForegroundColor Yellow
                try {
                    & $restoreScript
                    Write-Host " OK" -ForegroundColor Green
                    # Zamezit opakovanému rollbacku — smazat backup po obnově
                    Remove-Item -Path $BackupPath -Recurse -Force -ErrorAction SilentlyContinue
                } catch {
                    Write-Host " FAIL" -ForegroundColor Red
                    Write-Host "  ❌  Rollback selhal: $_" -ForegroundColor Red
                    Write-Host "  ⚠  Ruční obnova: powershell -File `"$restoreScript`"" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  ⚠  RESTORE.ps1 nenalezen v $BackupPath" -ForegroundColor Yellow
            }
        }
        return $false
    }
}

# ─── Backup-Configuration ─────────────────────────────────────
# Vytvoří časovanou zálohu před změnami, s RESTORE skriptem
function Backup-Configuration {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupRoot = Join-Path $env:USERPROFILE ".dev-env" "backups"
    $backupDir = Join-Path $backupRoot $timestamp
    
    New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
    Write-Host "`n  💾  Záloha → $backupDir" -ForegroundColor Cyan
    
    $items = @()
    
    # 1. .gitconfig
    $gc = Join-Path $env:USERPROFILE ".gitconfig"
    if (Test-Path $gc) { Copy-Item $gc (Join-Path $backupDir ".gitconfig") -Force; $items += ".gitconfig" }
    
    # 2. PowerShell profil
    $pp = Join-Path $env:USERPROFILE "Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    if (Test-Path $pp) { Copy-Item $pp (Join-Path $backupDir "profile.ps1") -Force; $items += "profile.ps1" }
    
    # 3. SSH (pouze pub + config, ne privátní)
    $ssh = Join-Path $env:USERPROFILE ".ssh"
    if (Test-Path $ssh) {
        $d = Join-Path $backupDir "ssh"; New-Item -Path $d -ItemType Directory -Force | Out-Null
        Get-ChildItem $ssh -Include "*.pub","config","known_hosts" | ForEach-Object {
            Copy-Item $_.FullName (Join-Path $d $_.Name) -Force; $items += "ssh/$($_.Name)"
        }
    }
    
    # 4. PATH snapshot (pro rollback)
    @{ timestamp=$timestamp; userPath=[Environment]::GetEnvironmentVariable("Path","User")
       systemPath=[Environment]::GetEnvironmentVariable("Path","Machine")
       envPath=$env:PATH } | ConvertTo-Json -Depth 2 |
       Out-File (Join-Path $backupDir "path-snapshot.json"); $items += "path-snapshot.json"
    
    # 5. OneDrive registry export
    if (Test-Path "HKCU:\Software\Microsoft\OneDrive\Accounts") {
        reg export "HKCU:\Software\Microsoft\OneDrive\Accounts" (Join-Path $backupDir "onedrive-registry.reg") 2>$null
        if (Test-Path (Join-Path $backupDir "onedrive-registry.reg")) { $items += "onedrive-registry.reg" }
    }
    
    # 6. RESTORE skript
    @"
# RESTORE — $timestamp
# Spustit: powershell -File "$backupDir\RESTORE.ps1"
`$backupDir = "$backupDir"
if (Test-Path "`$backupDir\.gitconfig") { Copy-Item "`$backupDir\.gitconfig" "`$env:USERPROFILE\.gitconfig" -Force }
if (Test-Path "`$backupDir\ssh") { Get-ChildItem "`$backupDir\ssh" | ForEach-Object { Copy-Item `$_.FullName "`$env:USERPROFILE\.ssh\" -Force } }
Write-Host "Obnoveno z: `$backupDir" -ForegroundColor Green
"@ | Out-File (Join-Path $backupDir "RESTORE.ps1") -Encoding UTF8; $items += "RESTORE.ps1"
    
    Write-Host "  ✅  $($items.Count) položek zazálohováno" -ForegroundColor Green
    Write-Host "  ▶   Obnova: powershell -File `"$(Join-Path $backupDir 'RESTORE.ps1')`"" -ForegroundColor DarkGray
    return @{ backupDir=$backupDir; items=$items }
}

# ─── Idempotence check ────────────────────────────────────────
# Pokud už bylo opraveno se stejným fingerprintem, přeskočit
$stateFile = Join-Path $env:USERPROFILE ".dev-env" "last-repair-state.json"
$currentFingerprint = -join (([Security.Cryptography.SHA256]::Create().ComputeHash(
    [Text.Encoding]::UTF8.GetBytes("$env:COMPUTERNAME|$env:USERNAME|$env:USERDOMAIN")
)) | ForEach-Object { $_.ToString("x2") })

if (Test-Path $stateFile) {
    try {
        $lastState = Get-Content $stateFile -Raw | ConvertFrom-Json
        if ($lastState.fingerprint -eq $currentFingerprint -and -not $Force) {
            Write-Host "  ✅  Stav již byl opraven (fingerprint shodný)" -ForegroundColor Green
            Write-Host "      Poslední oprava: $($lastState.lastRepair)" -ForegroundColor DarkGray
            Write-Host "      Pro přeopravení použij -Force" -ForegroundColor DarkGray
            exit 0
        }
    } catch { Write-Host "  ⚠  Stavový soubor poškozen, provádím novou detekci" -ForegroundColor Yellow }
}

# Funkce pro uložení stavu po úspěšné opravě
function Save-RepairState {
    param([int]$FixedIssues, [int]$TotalIssues)
    $state = [ordered]@{
        lastRepair  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        fingerprint = $currentFingerprint
        hostname    = $env:COMPUTERNAME
        fixedIssues = $FixedIssues
        totalIssues = $TotalIssues
        repairedAt  = (Get-Date).ToString("o")
    }
    $stateDir = Split-Path $stateFile -Parent
    if (-not (Test-Path $stateDir)) { New-Item -Path $stateDir -ItemType Directory -Force | Out-Null }
    $state | ConvertTo-Json -Depth 3 | Out-File $stateFile -Encoding UTF8
    Write-Host "  💾  Stav uložen: $stateFile" -ForegroundColor DarkGray
}

# Backup před kritickými změnami
if (-not $SkipBackup -and $PSCmdlet.ShouldProcess("Configuration backup", "Create backup before repair")) {
    $backup = Backup-Configuration
}
$fixes = 0; $issues = 0

# 1. HOME env variable
if (-not $env:HOME) {
    $issues++
    Write-Host "[ISSUE] HOME not set / nenastaveno" -ForegroundColor Red
    if ($PSCmdlet.ShouldProcess("HOME=$env:USERPROFILE", "Set HOME environment variable")) {
        [Environment]::SetEnvironmentVariable("HOME", $env:USERPROFILE, "User")
        Write-Host "  FIXED" -ForegroundColor Green
    }
}

# 2. PATH duplicates — per-scope analýza + dedup
Write-Host ""
Write-Host "─── 2. PATH duplicity / duplicitní cesty ──────────────" -ForegroundColor Cyan

# Načtení obou scopů
$sysPathRaw = [Environment]::GetEnvironmentVariable("PATH", "Machine")
$usrPathRaw = [Environment]::GetEnvironmentVariable("PATH", "User")
$sysEntries = if ($sysPathRaw) { $sysPathRaw -split ';' | Where-Object { $_ -ne '' } } else { @() }
$usrEntries = if ($usrPathRaw) { $usrPathRaw -split ';' | Where-Object { $_ -ne '' } } else { @() }
$comEntries = $env:PATH -split ';' | Where-Object { $_ -ne '' }

# Helper: najdi duplicity v poli
function Get-Duplicates($Entries) {
    return $Entries | Group-Object | Where-Object Count -gt 1
}

$sysDupes = Get-Duplicates $sysEntries
$usrDupes = Get-Duplicates $usrEntries
$comDupes = Get-Duplicates $comEntries

# Cross-scope duplicity (stejná cesta v System i User)
$crossDupes = @()
foreach ($s in $sysEntries) {
    $sNorm = $s.TrimEnd('\')
    foreach ($u in $usrEntries) {
        if ($sNorm -eq $u.TrimEnd('\')) { $crossDupes += $sNorm; break }
    }
}
$crossDupes = $crossDupes | Select-Object -Unique

$totalDupes = $sysDupes.Count + $usrDupes.Count + $crossDupes.Count

if ($totalDupes -gt 0) {
    $issues += $totalDupes
    Write-Host "  ⚠  Nalezeno $totalDupes duplicit:" -ForegroundColor Yellow
    
    # System scope duplicity (vyžadují admina)
    if ($sysDupes.Count -gt 0) {
        Write-Host "  [SYSTEM] $($sysDupes.Count) duplicit v System PATH (vyžaduje admin opravu):" -ForegroundColor Red
        foreach ($d in $sysDupes) { Write-Host "      ⚠  $($d.Name) (x$($d.Count))" -ForegroundColor Red }
    }
    
    # User scope duplicity (lze opravit)
    if ($usrDupes.Count -gt 0) {
        Write-Host "  [USER]   $($usrDupes.Count) duplicit v User PATH (lze opravit):" -ForegroundColor Yellow
        foreach ($d in $usrDupes) { Write-Host "      ✗  $($d.Name) (x$($d.Count))" -ForegroundColor Yellow }
    }
    
    # Cross-scope duplicity
    if ($crossDupes.Count -gt 0) {
        Write-Host "  [CROSS]  $($crossDupes.Count) cest je v System i User scope:" -ForegroundColor Yellow
        foreach ($c in $crossDupes) { Write-Host "      ✗  $c" -ForegroundColor Yellow }
        Write-Host "      → Náprava: odebrat z User PATH, ponechat v System" -ForegroundColor DarkGray
    }
    
    # Oprava: deduplikace User PATH
    $fixTargets = @()
    if ($usrDupes.Count -gt 0) { $fixTargets += "$($usrDupes.Count) User duplicit" }
    if ($crossDupes.Count -gt 0) { $fixTargets += "$($crossDupes.Count) cross-scope (odebrat z User)" }
    
    if ($fixTargets.Count -gt 0) {
        $fixLabel = $fixTargets -join ', '
        if ($PSCmdlet.ShouldProcess($fixLabel, "Deduplicate User PATH")) {
            # Zabaleno do Invoke-EnvironmentRepair pro automatický rollback
            $repairDedup = $false
            $repairOk = Invoke-EnvironmentRepair -RepairAction {
                # Zachovat první výskyt každé cesty v User scope
                $seen = @{}
                $dedupedUser = $usrEntries | Where-Object {
                    $normalized = $_.TrimEnd('\')
                    if (-not $seen.ContainsKey($normalized)) { $seen[$normalized] = $true; return $true }
                    return $false
                }
                # Odebrat cross-scope duplicity (nechat v System)
                $cleanedUser = $dedupedUser | Where-Object {
                    $norm = $_.TrimEnd('\')
                    $isInSystem = $sysEntries | Where-Object { $_.TrimEnd('\') -eq $norm } | Select-Object -First 1
                    -not $isInSystem
                }
                if ($cleanedUser.Count -eq 0 -and $dedupedUser.Count -gt 0) { $cleanedUser = $dedupedUser }
                
                $newPath = $cleanedUser -join ';'
                [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
                $env:PATH = ($sysEntries -join ';') + ';' + $newPath
                $script:repairDedup = ($usrEntries.Count - $cleanedUser.Count)  # uložit počet pro výpis
                
                # Ověření: zkontrolovat, že duplicity zmizely
                $afterPath = $env:PATH -split ';' | Where-Object { $_ -ne '' }
                $remainingDupes = $afterPath | Group-Object | Where-Object Count -gt 1
                if ($remainingDupes) { throw "Duplicisty stále existují: $($remainingDupes.Name -join ', ')" }
            } -ActionName "PATH dedup" -BackupPath $backup.backupDir -VerifyAction { $true }
            
            if ($repairOk) {
                Write-Host "  ✅  User PATH vyčištěna: $repairDedup duplicit odstraněno" -ForegroundColor Green
                Write-Host "  ℹ   System PATH duplicity vyžadují ruční opravu (Admin)" -ForegroundColor DarkGray
                $fixes++
            }
        }
    } else {
        Write-Host "  ℹ   Pouze System PATH duplicity — nelze opravit bez Admin práv" -ForegroundColor DarkGray
    }
} else {
    Write-Host "  ✅  Žádné duplicity v PATH" -ForegroundColor Green
}

# 3. PATH missing entries — per-scope analýza + cleanup
Write-Host ""
Write-Host "─── 3. PATH chybějící cesty / missing entries ────────" -ForegroundColor Cyan

# Chybějící v System PATH
$sysMissing = $sysEntries | Where-Object {
    try { -not (Test-Path ([Environment]::ExpandEnvironmentVariables($_))) } catch { $true }
}
# Chybějící v User PATH
$usrMissing = $usrEntries | Where-Object {
    try { -not (Test-Path ([Environment]::ExpandEnvironmentVariables($_))) } catch { $true }
}

$totalMissing = $sysMissing.Count + $usrMissing.Count

if ($totalMissing -gt 0) {
    $issues += $totalMissing
    Write-Host "  ⚠  Nalezeno $totalMissing chybějících cest:" -ForegroundColor Yellow
    
    # System missing (vyžaduje admina)
    if ($sysMissing.Count -gt 0) {
        Write-Host "  [SYSTEM] $($sysMissing.Count) chybějících v System PATH (vyžaduje admin opravu):" -ForegroundColor Red
        foreach ($m in $sysMissing) { Write-Host "      ❌  $m" -ForegroundColor Red }
    }
    
    # User missing (lze opravit)
    if ($usrMissing.Count -gt 0) {
        Write-Host "  [USER]   $($usrMissing.Count) chybějících v User PATH:" -ForegroundColor Yellow
        foreach ($m in $usrMissing) { Write-Host "      ❌  $m" -ForegroundColor Yellow }
    }
    
    # Oprava: odstranit chybějící z User PATH
    if ($usrMissing.Count -gt 0) {
        $usrMissingList = $usrMissing -join ', '
        if ($PSCmdlet.ShouldProcess($usrMissingList, "Remove missing entries from User PATH")) {
            $repairOk = Invoke-EnvironmentRepair -RepairAction {
                $cleanUser = $usrEntries | Where-Object { $_ -notin $usrMissing }
                $newPath = $cleanUser -join ';'
                [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
                $env:PATH = ($sysEntries -join ';') + ';' + $newPath
                
                # Ověření: chybějící cesty už nejsou v runtime PATH
                $afterMissing = $env:PATH -split ';' | Where-Object { $_ -ne '' } | Where-Object {
                    try { -not (Test-Path ([Environment]::ExpandEnvironmentVariables($_))) } catch { $true }
                }
                if ($afterMissing) { throw "Stále existují chybějící cesty: $($afterMissing -join '; ')" }
            } -ActionName "PATH cleanup ($($usrMissing.Count) missing)" -BackupPath $backup.backupDir
            
            if ($repairOk) { $fixes++ }
        }
    } else {
        Write-Host "  ℹ   Chybějící cesty pouze v System PATH — vyžaduje Admin opravu" -ForegroundColor DarkGray
    }
} else {
    Write-Host "  ✅  Všechny cesty v PATH existují" -ForegroundColor Green
}

# 4. OneDrive folder redirects — detailed detection + repair
Write-Host ""
Write-Host "─── 4. OneDrive / Known Folder Move ─────────────────" -ForegroundColor Cyan

# 4.0 KFM safety check — bez -Force neopravovat KFM
$kfmDetected = $false
foreach ($rp in @("HKCU:\Software\Microsoft\OneDrive\Accounts\Personal",
                  "HKCU:\Software\Microsoft\OneDrive\Accounts\Business1")) {
    if (Test-Path $rp) {
        $kfmVal = (Get-ItemProperty -Path $rp -Name "IsKFMEnabled" -ErrorAction SilentlyContinue).IsKFMEnabled
        if ($kfmVal -eq 1) { $kfmDetected = $true; break }
    }
}

if ($kfmDetected -and -not $Force) {
    $issues++
    Write-Host ""
    Write-Host "  ❌  KRITICKÉ: OneDrive Known Folder Move je AKTIVNÍ" -ForegroundColor Red
    Write-Host "      Bez -Force nelze bezpečně upravit OneDrive přesměrování." -ForegroundColor Yellow
    Write-Host "      Ruční postup:" -ForegroundColor Yellow
    Write-Host "      1. Otevřít OneDrive → Nastavení → Zálohování → Spravovat zálohování" -ForegroundColor Cyan
    Write-Host "      2. Kliknout na složku → Zastavit zálohování" -ForegroundColor Cyan
    Write-Host "      3. Poté spustit: .\60-repair.ps1 -Force" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "      ⚠  S -Force se pokusíme o opravu (riskantní!)" -ForegroundColor Red
}

# 4.1 Zjištění cesty OneDrivu
$odPath = $null
foreach ($rp in @("HKCU:\Software\Microsoft\OneDrive\Accounts\Personal",
                  "HKCU:\Software\Microsoft\OneDrive\Accounts\Business1")) {
    if (Test-Path $rp) {
        $folder = (Get-ItemProperty $rp -ErrorAction SilentlyContinue).UserFolder
        if ($folder) { $odPath = $folder; break }
    }
}
if (-not $odPath) { $odPath = [Environment]::GetEnvironmentVariable("OneDrive", "User") }

if ($odPath) {
    Write-Host "  📁 OneDrive: $odPath" -ForegroundColor DarkGray
} else {
    Write-Host "  ℹ   OneDrive není nainstalován / nastaven" -ForegroundColor DarkGray
}

# 4.2 Kontrola všech 5 Known Folders přes [Environment]::GetFolderPath()
$knownFolderMap = [ordered]@{
    "Desktop"   = @{ cz = "Plocha";     api = "Desktop";    reg = "Desktop" }
    "Documents" = @{ cz = "Dokumenty";  api = "MyDocuments"; reg = "Documents" }
    "Pictures"  = @{ cz = "Obrázky";    api = "MyPictures"; reg = "Pictures" }
    "Music"     = @{ cz = "Hudba";      api = "MyMusic";    reg = "Music" }
    "Videos"    = @{ cz = "Videa";      api = "MyVideos";   reg = "Videos" }
}
$redirectedFolders = @()

foreach ($enName in $knownFolderMap.Keys) {
    $info = $knownFolderMap[$enName]
    $resolvedPath = [Environment]::GetFolderPath($info.api)
    if ($resolvedPath -match 'OneDrive') {
        # Lokální cesta = USERPROFILE + poslední segment OneDrive cesty
        $leaf = Split-Path $resolvedPath -Leaf
        $localPath = Join-Path $env:USERPROFILE $leaf
        $redirectedFolders += @{
            cz    = $info.cz
            en    = $info.reg
            path  = $resolvedPath   # OneDrive cesta
            local = $localPath      # cílová lokální cesta
        }
    }
}

# 4.3 Zobrazení výsledku + nabídka opravy
if ($redirectedFolders.Count -gt 0) {
    $issues += $redirectedFolders.Count
    Write-Host ""
    Write-Host "  ⚠  $($redirectedFolders.Count) systémových složek je přesměrováno do OneDrivu:" -ForegroundColor Yellow
    
    # Měření velikosti přesměrovaných složek
    foreach ($rf in $redirectedFolders) {
        $folderSize = ""
        try {
            if (Test-Path $rf.path) {
                $items = Get-ChildItem -Path $rf.path -Recurse -ErrorAction SilentlyContinue
                $size = $items | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue
                $count = ($items | Where-Object { -not $_.PSIsContainer } | Measure-Object).Count
                if ($size.Sum -ge 1GB) {
                    $folderSize = " ($([math]::Round($size.Sum / 1GB, 1))) GB, $count souborů"
                } elseif ($size.Sum -ge 1MB) {
                    $folderSize = " ($([math]::Round($size.Sum / 1MB, 0))) MB, $count souborů"
                } else {
                    $folderSize = ", $count souborů"
                }
            }
        } catch {}
        Write-Host "  ✗   $($rf.cz) → $($rf.path)$folderSize" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "  ─── DOPORUČENÍ ─────────────────────────────────" -ForegroundColor Cyan
    Write-Host "  Při vypnutí zálohování OneDrivu se soubory" -ForegroundColor White
    Write-Host "  PŘESUNOU zpět do C:\Users\spravce\ — nedojde ke ztrátě." -ForegroundColor White
    Write-Host "  Data zůstanou v OneDrivu v cloudu i po přesunu." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Chcete otevřít nastavení zálohování OneDrivu?" -ForegroundColor Yellow
    Write-Host "  (OneDrive → Nastavení → Zálohování → Spravovat zálohování)" -ForegroundColor DarkGray
    Write-Host "  Poté klikněte na složku → Zastavit zálohování" -ForegroundColor DarkGray
    
    if ($PSCmdlet.ShouldProcess("OneDrive Backup Settings", "Open OneDrive settings page")) {
        try {
            Start-Process "ms-settings:backup"
            Write-Host "  ✅  Otevřeno Nastavení → Účty → Zálohování" -ForegroundColor Green
            Write-Host "      Klikněte na 'Spravovat zálohování OneDrivu'" -ForegroundColor Cyan
            Write-Host "      a vypněte složky, které chcete vrátit do lokálního umístění" -ForegroundColor Cyan
            $fixes++
        } catch {
            try {
                # Fallback: otevřít OneDrive přímo
                Start-Process "onedrive:"
                Write-Host "  ⚠  Otevřen OneDrive — přejděte do Nastavení → Zálohování" -ForegroundColor Yellow
                $fixes++
            } catch {
                Write-Host "  ❌  Nelze otevřít nastavení — otevřete ručně:" -ForegroundColor Red
                Write-Host "      Nastavení → Účty → Zálohování Windows → OneDrive" -ForegroundColor Cyan
            }
        }
    }
} else {
    Write-Host "  ✅  Žádné složky nejsou přesměrovány do OneDrivu" -ForegroundColor Green
}

# 4.4 Automatické vrácení přesměrovaných složek (pouze pokud NENÍ KFM)
if ($redirectedFolders.Count -gt 0 -and -not $kfmDetected -and $Force) {
    Write-Host ""
    Write-Host "─── 4.4 Vrácení složek z OneDrivu ─────────────────" -ForegroundColor Cyan
    
    $repairOk = Invoke-EnvironmentRepair -RepairAction {
        foreach ($rf in $redirectedFolders) {
            Write-Host "  📦  $($rf.cz): přesun zpět ..." -NoNewline -ForegroundColor Yellow
            
            # Lokální cesta = USERPROFILE + poslední segment OD cesty
            $localFolder = $rf.local
            $regName = $rf.en
            
            # 1. Kopírovat soubory z OneDrivu do lokální složky
            if ((Test-Path $rf.path) -and (Get-ChildItem $rf.path -ErrorAction SilentlyContinue)) {
                if (-not (Test-Path $localFolder)) {
                    New-Item -Path $localFolder -ItemType Directory -Force | Out-Null
                }
                Copy-Item -Path "$($rf.path)\*" -Destination $localFolder -Recurse -Force -ErrorAction Stop
                Write-Host " OK" -NoNewline -ForegroundColor Green
            } else {
                Write-Host " (prázdná)" -NoNewline -ForegroundColor DarkGray
            }
            
            # 2. Přesměrovat registry zpět na lokální cestu
            $regKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
            if (Test-Path $regKey) {
                Set-ItemProperty -Path $regKey -Name $regName -Value $localFolder -ErrorAction Stop
                Write-Host " reg" -NoNewline -ForegroundColor DarkGray
            }
            
            # 3. Také nastavit pro Shell Folders (ne User Shell Folders)
            $regKey2 = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
            if (Test-Path $regKey2) {
                Set-ItemProperty -Path $regKey2 -Name $regName -Value $localFolder -ErrorAction SilentlyContinue
            }
            
            Write-Host " ✅" -ForegroundColor Green
            Write-Log "OneDrive $($rf.cz) vraceno: $($rf.path) → $localFolder" "INFO"
            $fixes++
        }
        
        # Ověření: registry je okamžitý, [Environment]::GetFolderPath() cachuje do odhlášení
        $stillRedirected = @()
        $regKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
        foreach ($rf in $redirectedFolders) {
            $regVal = if (Test-Path $regKey) { (Get-ItemProperty $regKey -Name $rf.en -ErrorAction SilentlyContinue).$rf.en } else { $null }
            if (-not ($regVal -and $regVal -notmatch 'OneDrive')) { $stillRedirected += $rf.cz }
        }
        if ($stillRedirected.Count -gt 0) {
            Write-Log "Registry verification failed for: $($stillRedirected -join ', ')" "ERROR"
            throw "Stále přesměrováno dle registru: $($stillRedirected -join ', ')"
        }
        Write-Log "OneDrive redirect fix: ověřeno v registru, $($redirectedFolders.Count) složek vráceno" "INFO"
        Write-Host "  ✅  Registry aktualizován — změny se projeví po odhlášení" -ForegroundColor Green
    } -ActionName "OneDrive folder restore ($($redirectedFolders.Count) folders)" -BackupPath $backup.backupDir
    
    if (-not $repairOk) {
        Write-Log "OneDrive folder restore SELHALO" "ERROR"
    }
} elseif ($redirectedFolders.Count -gt 0 -and $kfmDetected -and $Force) {
    Write-Log "OneDrive KFM active - cannot auto-fix, skipping" "WARN"
    Write-Host "  ⚠  KFM aktivní — automatická oprava není možná" -ForegroundColor Yellow
    Write-Host "      Vypněte ručně v OneDrive → Nastavení → Zálohování" -ForegroundColor Cyan
}

# 5. SSH keys existence
if (-not (Test-Path "$env:USERPROFILE\.ssh")) {
    $issues++
    Write-Host "[ISSUE] No SSH directory / chybí .ssh" -ForegroundColor Red
    if ($PSCmdlet.ShouldProcess("~/.ssh/", "Create SSH directory")) {
        New-Item -ItemType Directory -Path "$env:USERPROFILE\.ssh" -Force | Out-Null
        Write-Host "  Created ~/.ssh/" -ForegroundColor Green
    }
}
$sshKeys = Get-ChildItem "$env:USERPROFILE\.ssh\id_*" -ErrorAction SilentlyContinue
if (-not $sshKeys) {
    $issues++
    Write-Host "[ISSUE] No SSH keys found / chybí SSH klíče" -ForegroundColor Red
    Write-Host "  Fix: ssh-keygen -t ed25519 -C your@email" -ForegroundColor Cyan
}

# Uložit stav po opravě (idempotence)
if ($issues -eq 0 -or $Force) {
    Save-RepairState -FixedIssues $fixes -TotalIssues $issues
}

# Summary
Write-Host ""
if ($issues -eq 0) {
    Write-Host "  ✅  No issues / žádné problémy" -ForegroundColor Green
} else {
    Write-Host "  ⚠  $issues issues found / nalezeno" -ForegroundColor Yellow
    if (-not $Force -and -not $WhatIf) { Write-Host "  Run with -WhatIf or -Force / Spust s -WhatIf nebo -Force" -ForegroundColor Cyan }
}
Write-Host ""
Write-Log "Phase 60 complete: $fixes fixes, $issues issues" "INFO"
Write-Host ">>> 60 — environment-repair OK" -ForegroundColor Green
if ($fixes -gt 0) { Write-Host "  ✅  $fixes oprav aplikováno" -ForegroundColor Green }
Write-Host "  issues: $issues, proceeding with phase 70" -ForegroundColor DarkGray
Write-Host "  📝  Log: $logFile" -ForegroundColor DarkGray
