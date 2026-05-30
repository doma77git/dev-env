#!/usr/bin/env pwsh
# === bootstrap.ps1 ============================================
# URL:    https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5
# ROLE:   Detect environment + point to repo + clone (if git)
#         Detekce prostředí + pointer na repo + clone (pokud git)
# RUN:    irm <url> | iex                                      (Windows)
#         $env:DEV_ENV_WHATIF='1'; irm <url> | iex              (dry-run)
#         ./bootstrap.ps1 -WhatIf                               (dry-run local)
# PARTNER: bootstrap.sh — curl -fsSL <url> | bash               (Linux/WSL)
# PATTERN: curl -fsSL <url>/bootstrap.sh | bash (dotfiles standard)
# ==============================================================
param([switch]$WhatIf)
# Support dry-run via env var for piped invocation (irm | iex can't pass params)
if (-not $WhatIf) { $WhatIf = [bool]([Environment]::GetEnvironmentVariable('DEV_ENV_WHATIF')) }
if ($WhatIf) { Write-Host ">>> DRY-RUN MODE / SUCHÝ BĚH" -ForegroundColor Magenta }

$RepoUrl  = "https://github.com/doma77git/dev-env"                # REPO — kam ukazuje gist
$RepoDir  = Join-Path $env:USERPROFILE ".dev-env/repo"         # LOCAL — kam se klonuje
$ErrorActionPreference = "Continue"                             # NEPADAT — pokračovat i při chybě

# ═══ PHASE 00/8 — BOOTSTRAP — gist entry point ═══════════════
#         Bootstrap header — odkud se spouští
$GistUrl = "https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5"
Write-Host ">>> PHASE 00 — BOOTSTRAP" -ForegroundColor Cyan
Write-Host "  running gist from → $GistUrl" -ForegroundColor DarkGray
Write-Host ""
Write-Host ">>> 00 — bootstrap OK" -ForegroundColor Green
Write-Host "  no recommendation, all OK proceeding with phase 01" -ForegroundColor DarkGray

# ═══ PHASE 01 — PROFILE — corporate / home / server / lab ══════
#         Inline profile detect (cheap, no scripts needed)
Write-Host ""
Write-Host ">>> PHASE 01 — PROFILE DETECT / DETEKCE PROFILU" -ForegroundColor Cyan

$csQuick = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
$osQuick = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue

$safeMode = $false
$ProfileName = "home"

if ($csQuick.PartOfDomain -and $env:USERDOMAIN -ne "WORKGROUP") {
    $ProfileName = "work"
    $safeMode = $true
    Write-Host "  🏢 WORK — corporate domain: $($csQuick.Domain)" -ForegroundColor Yellow
} elseif ($osQuick.Caption -match "Server") {
    $ProfileName = "server"
    $safeMode = $true
    Write-Host "  🖳 SERVER — headless OS: $($osQuick.Caption)" -ForegroundColor DarkCyan
} elseif ($csQuick.Manufacturer -match "VMware|VirtualBox" -or $csQuick.Model -match "Virtual") {
    $ProfileName = "lab"
    Write-Host "  🧪 LAB — virtual machine: $($csQuick.Manufacturer) $($csQuick.Model)" -ForegroundColor Magenta
} else {
    Write-Host "  🏠 HOME — personal PC" -ForegroundColor Green
}

if ($safeMode) {
    Write-Host "  🔒 SAFE MODE — no automatic installs" -ForegroundColor DarkYellow
} else {
    Write-Host "  ✅ Full mode — will install missing essentials" -ForegroundColor Cyan
}

Write-Host ""
Write-Host ">>> 01 — profile detect OK" -ForegroundColor Green
Write-Host "  profile: $ProfileName$(if($safeMode){', safeMode=true'})" -ForegroundColor DarkGray

# ═══ PHASE 02 — CORE CHECK — PS7, shell, terminal, installer ═══
Write-Host ""
Write-Host ">>> PHASE 02 — CORE CHECK / ZÁKLADNÍ KONTROLA" -ForegroundColor Cyan

$psMajor = $PSVersionTable.PSVersion.Major
$isPS7 = ($psMajor -ge 7)

if ($isPS7) {
    Write-Host "  ✅ PowerShell $($PSVersionTable.PSVersion.ToString()) — OK" -ForegroundColor Green
} elseif ($safeMode) {
    Write-Host "  ❌ PowerShell $psMajor (need 7+) — safe mode, skip install" -ForegroundColor Yellow
    Write-Host "     Install manually: https://github.com/PowerShell/PowerShell/releases" -ForegroundColor DarkGray
} else {
    Write-Host "  ❌ PowerShell $psMajor — attempting upgrade ..." -ForegroundColor Yellow
    
    # Try winget first
    $wingetOk = $null
    try { $wingetOk = Get-Command winget -ErrorAction Stop } catch {}
    if ($wingetOk) {
        Write-Host "     winget install Microsoft.PowerShell ..." -ForegroundColor Yellow
        winget install --id Microsoft.PowerShell --accept-source-agreements --silent 2>$null
    }
    
    # Check if pwsh exists now
    $pwshPaths = @("$env:ProgramFiles\PowerShell\7\pwsh.exe", "${env:ProgramFiles(x86)}\PowerShell\7\pwsh.exe")
    $pwshExe = $null
    foreach ($p in $pwshPaths) { if (Test-Path $p) { $pwshExe = $p; break } }
    
    if (-not $pwshExe) {
        # Direct MSI download
        Write-Host "     Direct download Microsoft.PowerShell MSI ..." -ForegroundColor Yellow
        $msiUrl = "https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/PowerShell-7.4.6-win-x64.msi"
        $msiPath = Join-Path $env:TEMP "PowerShell-7.4.6-win-x64.msi"
        try {
            (New-Object Net.WebClient).DownloadFile($msiUrl, $msiPath)
            Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /quiet /norestart ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ENABLE_PSREMOTING=1" -Wait
            Remove-Item $msiPath -Force -ErrorAction SilentlyContinue
            # Check again
            foreach ($p in $pwshPaths) { if (Test-Path $p) { $pwshExe = $p; break } }
        } catch { Write-Host "     Download failed: $_" -ForegroundColor Red }
    }
    
    if ($pwshExe) {
        Write-Host "  ✅ PowerShell 7 installed at $pwshExe" -ForegroundColor Green
        Write-Host "  Spawning new pwsh window with full pipeline ..." -ForegroundColor Cyan
        # Write temp script and spawn pwsh
        $tempBootstrap = Join-Path $env:TEMP "dev-env-bootstrap.ps1"
        $gistBootstrap = "https://gist.githubusercontent.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1"
        @"
`$env:DEV_ENV_WHATIF = '$(if ($WhatIf) { '1' } else { '' })'
Write-Host '>>> Pipeline continues in PowerShell 7 ...' -ForegroundColor Cyan
irm '$gistBootstrap' | iex
Write-Host ''
Write-Host '=== Pipeline complete ===' -ForegroundColor Green
Read-Host 'Press Enter to close'
"@ | Set-Content $tempBootstrap -Encoding UTF8
        Start-Process $pwshExe -ArgumentList "-NoProfile -File `"$tempBootstrap`"" -WindowStyle Normal
        exit 0
    } else {
        Write-Host "  ❌ Could not install PowerShell 7" -ForegroundColor Red
        Write-Host "     Install manually: https://github.com/PowerShell/PowerShell/releases" -ForegroundColor DarkGray
    }
}

# Check shell, terminal, installer (informational only)
$wtCmd = $null; try { $wtCmd = Get-Command wt -ErrorAction Stop } catch {}
Write-Host "  $(if ($isPS7) { '✅' } else { '⬚' }) Shell: pwsh $($PSVersionTable.PSVersion.ToString())" -ForegroundColor $(if ($isPS7) { 'Green' } else { 'DarkGray' })
Write-Host "  $(if ($wtCmd) { '✅' } else { '⬚' }) Terminal: $(if ($wtCmd) { (Get-Command wt).Source } else { 'not installed' })" -ForegroundColor $(if ($wtCmd) { 'Green' } else { 'DarkGray' })
$wingetCheck = $null; try { $wingetCheck = Get-Command winget -ErrorAction Stop } catch {}
Write-Host "  $(if ($wingetCheck) { '✅' } else { '⬚' }) Installer: $(if ($wingetCheck) { 'winget' } else { 'none found — manual install' })" -ForegroundColor $(if ($wingetCheck) { 'Green' } else { 'DarkGray' })

Write-Host ""
Write-Host ">>> 02 — core check OK" -ForegroundColor Green
Write-Host "  $(if ($isPS7) { 'Proceeding with phase 10' } else { 'PS5 — limited pipeline mode' })" -ForegroundColor DarkGray

# ═══ PHASE 10 — DETECT — inventura stroje (self‑contained, no git) ═══
#         Inventory — nepotřebuje git, vše je uvnitř
Write-Host ""
Write-Host ">>> PHASE 10 — ENVIRONMENT DETECT / DETEKCE" -ForegroundColor Cyan

# 1a. Output dir — kam ukládáme reporty
#     Výstupní složka
$envDir = Join-Path $env:USERPROFILE ".dev-env"
if (-not (Test-Path $envDir)) { $null = New-Item -ItemType Directory -Path $envDir -Force }

# 1b. Fingerprint — SHA256(hostname|username|domain)
#     Jednoznačný otisk stroje
$hostname  = $env:COMPUTERNAME
$username  = $env:USERNAME
$domain    = $env:USERDOMAIN
$fingerprint = -join (([Security.Cryptography.SHA256]::Create().ComputeHash(
    [Text.Encoding]::UTF8.GetBytes("$hostname|$username|$domain")
)) | ForEach-Object { $_.ToString("x2") })

# 1c. Cache — minulý stav (machines.json)
#     Načíst historii detekcí
$machinesFile = Join-Path $envDir "machines.json"
$machines = @()
if (Test-Path $machinesFile) {
    try { $machines = @(Get-Content $machinesFile -Raw | ConvertFrom-Json) } catch {}
    $machines = @($machines)  # force array / vynutit pole (single entry bug)
}
$previous = $machines | Where-Object { $_.fingerprint -eq $fingerprint } | Select-Object -Last 1

# 1d. OS — verze, build, architektura
#     Operační systém
$os  = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
$cs  = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
$osInfo = [ordered]@{
    caption     = $os.Caption                                   # např. "Windows 11 Pro"
    build       = $os.BuildNumber                               # např. "26100"
    arch        = $os.OSArchitecture                             # "64-bit"
    installDate = ([DateTime]$os.InstallDate).ToString("yyyy-MM-dd")
    lastBoot    = ([DateTime]$os.LastBootUpTime).ToString("yyyy-MM-dd")
}

# 1e. Tools — nainstalované nástroje
#     Detekce nástrojů (Get-Command + --version)
$detectTools = @("git","node","python","code","winget","docker","gh","pwsh","curl","7z","nvim","scoop","nvm")
$tools = [ordered]@{}
foreach ($t in $detectTools) {
    $cmd = Get-Command $t -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) {
        $ver = try { (& $t --version 2>&1 | Select-Object -First 1) -join ' ' } catch { "?" }
        $tools[$t] = "$ver | $($cmd.Source)"                   # "v2.47.1 | C:\...\git.exe"
    } else { $tools[$t] = $null }
}

# 1f. PATH — analýza proměnné PATH
#     Počet položek, duplicity, neexistující cesty
$pathEntries = $env:PATH -split ';' | Where-Object { $_ -ne '' }
$pathErrors = @()
if ($pathEntries.Count -gt 50) { $pathErrors += "Count: $($pathEntries.Count)" }
$pathErrors += $pathEntries | Group-Object | Where-Object Count -gt 1 | ForEach-Object { "DUP: $($_.Name)" }
$pathErrors += $pathEntries | Where-Object { 
    try { -not (Test-Path ([Environment]::ExpandEnvironmentVariables($_))) } catch { $true }
} | ForEach-Object { "MISS: $_" }

# 1g. OneDrive — aktivní účty, přesměrované složky
#     Detekce OneDrive (osobní + firemní)
$odInfo = [ordered]@{}
foreach ($rp in @("HKCU:\Software\Microsoft\OneDrive\Accounts\Personal",
                  "HKCU:\Software\Microsoft\OneDrive\Accounts\Business1")) {
    if (Test-Path $rp) { $odInfo[(Split-Path $rp -Leaf)] = (Get-ItemProperty $rp -ErrorAction SilentlyContinue).UserFolder }
}
$odRedirects = @{}
if (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders") {
    foreach ($n in @("Desktop","Documents","Pictures","Downloads")) {
        $v = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name $n -ErrorAction SilentlyContinue).$n
        if ($v -and $v -match 'OneDrive') { $odRedirects[$n] = $v }
    }
}

# 1h. Corporate — firemní signály
#     Doména, proxy, výrobce hardware (VM detekce)
$corp = [ordered]@{
    domainJoined = $cs.PartOfDomain                              # true = v doméně
    domain       = $cs.Domain
    manufacturer = $cs.Manufacturer                              # "Dell", "VMware", ...
    model        = $cs.Model
    proxy        = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue).ProxyServer
}

# 1i. Status — porovnání s minulým stavem
#     new / same / os-changed / tools-changed
$status = "new"; $changes = @()
if ($previous) {
    $pOs = $previous.os
    if ($pOs.build -ne $osInfo.build) { 
        $status = "os-changed"                                   # reinstal / upgrade
        $changes += "OS build: $($pOs.build) → $($osInfo.build)"
    }
    # Robust comparison — handles incompatible $previous (buggy version, schema drift)
    try {
        $newToolNames = @(); $lostToolNames = @()
        $prevTools = if ($previous.tools) { $previous.tools } else { $null }
        foreach ($t in $detectTools) {
            $oldVal = try { $prevTools.$t } catch { $null }
            $newVal = $tools[$t]
            # Both absent → skip
            if (-not $oldVal -and -not $newVal) { continue }
            # Newly appeared
            if ((-not $oldVal) -and $newVal) { $newToolNames += $t; continue }
            # Disappeared
            if ($oldVal -and (-not $newVal)) { $lostToolNames += $t; continue }
            # Both present — compare values (stringify: PSObject vs hashtable types may differ)
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
        # Incompatible $previous structure → treat as fresh detection
        Write-Host "  ⚠ Previous report format changed — treating as new detection" -ForegroundColor DarkYellow
        $status = "new"
    }
    if ($changes.Count -eq 0) { $status = "same" }               # nic se nezměnilo
}

# 1j. Report — sestavit JSON
#     Strukturovaný výstup pro AI i člověka
$report = [ordered]@{
    pipeline = [ordered]@{
        phases    = [ordered]@{ "00"="bootstrap"; "01"="profile"; "02"="core-check"; "10"="environment-detect"; "15"="inventory-report"; "20"="repository-clone"; "30"="profile-identity"; "40"="essentials-setup"; "50"="categories-setup"; "60"="environment-repair"; "70"="validation-test" }
        completed = @("00","10","20","30","40")
        next      = "50"
        total     = 8
    }
    meta = [ordered]@{
        bootstrap = "1.0.0"
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
    path        = [ordered]@{ count = $pathEntries.Count; errors = @($pathErrors) }
    onedrive    = [ordered]@{ accounts = $odInfo; redirects = $odRedirects }
    corporate   = $corp
    changes     = @($changes)
}

# 1k. Uložit na disk
#     Write JSON → append to history
$json = $report | ConvertTo-Json -Depth 6
$reportPath = Join-Path $envDir "report-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').json"
$json | Set-Content -Path $reportPath -Encoding UTF8
$machines += $report
$machines | ConvertTo-Json -Depth 6 | Set-Content -Path $machinesFile -Encoding UTF8

Write-Host ""
Write-Host ">>> 10 — environment-detect OK" -ForegroundColor Green
Write-Host "  fingerprint: $fingerprint, OS: $($osInfo.caption) build $($osInfo.build), tools: $(($tools.GetEnumerator() | Where-Object { $_.Value -ne $null } | Measure-Object).Count)/$($detectTools.Count) detected" -ForegroundColor DarkGray

# ═══ PHASE 15 — REPORT — uložit JSON + zobrazit status ═════
#         Výstup pro uživatele
$icon = @{ "new"="🔴"; "same"="🟢"; "os-changed"="🟠"; "tools-changed"="🟡" }
Write-Host ""
Write-Host ">>> PHASE 15 — INVENTORY REPORT / VÝSLEDEK" -ForegroundColor Cyan
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  $($icon[$status])  $($status.ToUpper())" -ForegroundColor White
foreach ($c in $changes) { Write-Host "║    $c" -ForegroundColor Yellow }
Write-Host "║" -ForegroundColor Cyan
Write-Host "║  REPO : $RepoUrl" -ForegroundColor Cyan
Write-Host "║  RPT  : $reportPath" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host ""
Write-Host ">>> 15 — inventory-report OK" -ForegroundColor Green
Write-Host "  status: $status, proceeding with phase 20" -ForegroundColor DarkGray

# ═══ PHASE 20 — CLONE — stáhnout repo (jen když git existuje) ═══
#         git clone → ~/.dev-env/repo/
if ($tools.git -ne $null) {
    Write-Host ""
    Write-Host ">>> PHASE 20 — REPOSITORY CLONE / KLONOVÁNÍ" -ForegroundColor Cyan
    if ((Test-Path $RepoDir) -and (Test-Path "$RepoDir\.git")) {
        Write-Host "  Already exists / Repo existuje — pulling ..." -ForegroundColor Yellow
        try {
            git -C $RepoDir fetch origin
            git -C $RepoDir checkout master 2>$null
            git -C $RepoDir pull origin master
            # Fix tracking if misconfigured (main vs master)
            $upstream = git -C $RepoDir rev-parse --abbrev-ref '@{upstream}' 2>$null
            if ($upstream -notmatch 'origin/master') {
                git -C $RepoDir branch --set-upstream-to=origin/master master 2>$null
            }
        } catch { Write-Host "  Pull failed / selhal: $_" -ForegroundColor Red }
    } elseif (Test-Path $RepoDir) {
        # Directory exists but not a git repo (partial cleanup) — remove and reclone
        Write-Host "  Broken repo / poškozené repo — removing ..." -ForegroundColor Yellow
        try { Remove-Item $RepoDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}
        Write-Host "  git clone -b master $RepoUrl $RepoDir" -ForegroundColor Yellow
        try { git clone -b master $RepoUrl $RepoDir } catch { Write-Host "  Clone failed / selhal: $_" -ForegroundColor Red }
    } else {
        Write-Host "  git clone -b master $RepoUrl $RepoDir" -ForegroundColor Yellow
        try { git clone -b master $RepoUrl $RepoDir } catch { Write-Host "  Clone failed / selhal: $_" -ForegroundColor Red }
    }
    Write-Host "  Repo: $RepoDir" -ForegroundColor Green
    Write-Host ""
    Write-Host ">>> 20 — repository-clone OK" -ForegroundColor Green
    Write-Host "  repo at $RepoDir, proceeding with phase 30" -ForegroundColor DarkGray

    # ═══ PHASE 30 — PROFILE — detekce (home/work/lab) ═══════
    $profileScript = Join-Path $RepoDir "scripts\40-profile.ps1"
    if (Test-Path $profileScript) {
        Write-Host ""
        . $profileScript -WhatIf:$WhatIf
    }

    # ═══ PHASE 40 — ESSENTIALS — VŽDY dry-run first, pak potvrzení ═══
    Write-Host ""
    Write-Host ">>> PHASE 40 — ESSENTIALS SETUP / ZÁKLADNÍ INSTALACE" -ForegroundColor Green
    $setupScript = Join-Path $RepoDir "scripts\50-setup-$ProfileName.ps1"
    if (-not (Test-Path $setupScript)) {
        Write-Host "  ⚠ Setup script not found: 50-setup-$ProfileName.ps1" -ForegroundColor Yellow
        Write-Host "  Try manually: ./scripts/50-setup-home.ps1 -WhatIf" -ForegroundColor DarkCyan
    } elseif ($WhatIf) {
        Write-Host "  Dry-run mode — evaluating what would change ..." -ForegroundColor Magenta
        & $setupScript -WhatIf
        $report.pipeline.completed = @("00","10","20","30","40","50")
        $report.pipeline.next = "60"
    } else {
        # Normal run: show dry-run first, then ask for confirmation
        Write-Host "  Showing what would change (dry-run):" -ForegroundColor Magenta
        Write-Host ""
        & $setupScript -WhatIf
        Write-Host ""
        # Dot-source Confirm-Action
        $confirmScript = Join-Path $RepoDir "scripts\Confirm-Action.ps1"
        if (Test-Path $confirmScript) { . $confirmScript }
        if (Get-Command Confirm-Action -ErrorAction SilentlyContinue) {
            if (Confirm-Action "Apply setup changes?" 5) {
                & $setupScript -Force
            } else {
                Write-Host "  SKIPPED — run manually: ./scripts/50-setup-$ProfileName.ps1 -Force" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  Confirm-Action not available — run manually:" -ForegroundColor Yellow
            Write-Host "  ./scripts/50-setup-$ProfileName.ps1 -Force" -ForegroundColor Cyan
        }
    }

    # ═══ PHASE 60 — REPAIR ═══════════════════════════════════
    $repairScript = Join-Path $RepoDir "scripts\60-repair.ps1"
    if (Test-Path $repairScript) {
        if ($WhatIf) {
            & $repairScript -WhatIf
        } else {
            & $repairScript -WhatIf
            if (Get-Command Confirm-Action -ErrorAction SilentlyContinue) {
                if (Confirm-Action "Apply repairs?" 5) {
                    & $repairScript -Force
                }
            }
        }
    } else {
        Write-Host "  ⚠ 60-repair.ps1 not found" -ForegroundColor Yellow
    }

    # ═══ PHASE 70 — TEST ═════════════════════════════════════
    $testScript = Join-Path $RepoDir "scripts\70-test.ps1"
    if (Test-Path $testScript) {
        & $testScript
        $testResult = $LASTEXITCODE
        if ($testResult -eq 0) {
            Write-Host ">>> 70 — validation-test PASS (exit 0)" -ForegroundColor Green
        } else {
            Write-Host ">>> 70 — validation-test FAIL (exit $testResult)" -ForegroundColor Red
        }
        # Update pipeline JSON with test result
        $report.pipeline.testResult = if ($testResult -eq 0) { "pass" } else { "fail" }
    } else {
        Write-Host "  ⚠ 70-test.ps1 not found" -ForegroundColor Yellow
    }

    $report.pipeline.completed = @("00","10","20","30","40","50","60","70")
    $report.pipeline.next = $null
} else {
    Write-Host ""
    Write-Host ">>> PHASE 30 — GIT NOT FOUND — REMOTE FALLBACK" -ForegroundColor Yellow
    Write-Host "  Using raw.githubusercontent.com as remote script source" -ForegroundColor DarkGray
    $RepoRoot = "https://raw.githubusercontent.com/doma77git/dev-env/master"
    Write-Host "  RepoRoot: $RepoRoot" -ForegroundColor Green
    $usingFallback = $true
    Write-Host ""
    Write-Host ">>> 20 — remote-fallback OK" -ForegroundColor Green
    Write-Host "  remote source ready, proceeding with phase 40" -ForegroundColor DarkGray

    # ═══ PHASE 30 — PROFILE (remote) ═══
    # Minimal inline profile detection (no local scripts available)
    Write-Host ""
    Write-Host ">>> PHASE 30 — PROFILE & IDENTITY (remote)" -ForegroundColor Cyan
    $configDir = Join-Path $env:USERPROFILE ".dev-env\config"
    if (Test-Path "$configDir\profile.json") {
        $ProfileName = (Get-Content "$configDir\profile.json" -Raw | ConvertFrom-Json).profile
        Write-Host "  Profile: $ProfileName (saved)" -ForegroundColor Green
    } else {
        # Simple auto-detect
        if ($cs.PartOfDomain -and $env:USERDOMAIN -ne "WORKGROUP") {
            $ProfileName = "work"
        } elseif ($osInfo.caption -match "Server") {
            $ProfileName = "server"
        } elseif ($cs.Manufacturer -match "VMware|VirtualBox" -or $cs.Model -match "Virtual") {
            $ProfileName = "lab"
        } elseif ($corp.proxy) {
            $ProfileName = "work"
        } else {
            $ProfileName = "home"
        }
        Write-Host "  Profile: $ProfileName (auto-detected)" -ForegroundColor Green
    }
    Write-Host ""
    Write-Host ">>> 40 — profile-identity OK (remote)" -ForegroundColor Green

    # ═══ PHASE 40 — SETUP (remote, dry-run only) ═══
    if ($WhatIf -and $ProfileName) {
        Write-Host ""
        Write-Host ">>> PHASE 40 — ESSENTIALS SETUP (remote dry-run)" -ForegroundColor Magenta
        try {
            $setupUrl = "$RepoRoot/scripts/50-setup-$ProfileName.ps1"
            Write-Host "  irm $setupUrl | iex -WhatIf" -ForegroundColor DarkGray
            $setupResult = irm $setupUrl 2>&1
            if ($setupResult) { Invoke-Expression ($setupResult -join "`n") }
        } catch {
            Write-Host "  Remote setup failed: $_ — run manually" -ForegroundColor Yellow
            Write-Host "  irm $RepoRoot/scripts/50-setup-home.ps1 | iex" -ForegroundColor DarkCyan
        }
    }
}

# ═══ PIPELINE FINALIZATION ═════════════════════════════════════
# Update completed list — pick up phases that ran in both branches
if (-not $report.pipeline.completed.Contains("50")) {
    $report.pipeline.completed = @("00","10","20","30","40")
    $report.pipeline.next = "50"
}

# ═══ RAW JSON — pro kopírování AI agentovi ═══════════════════
# Re-serialize to pick up pipeline.completed/testResult updates
$json = $report | ConvertTo-Json -Depth 6
Write-Host ""
Write-Host $json
