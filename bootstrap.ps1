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
Write-Host ">>> PHASE 00/8 — BOOTSTRAP" -ForegroundColor Cyan
Write-Host "  running gist from → $GistUrl" -ForegroundColor DarkGray
Write-Host ""
Write-Host ">>> 00 — bootstrap OK" -ForegroundColor Green
Write-Host "  no recommendation, all OK proceeding with phase 01" -ForegroundColor DarkGray

# ═══ PHASE 01/8 — DETECT — inventura stroje (self‑contained, no git) ═══
#         Inventory — nepotřebuje git, vše je uvnitř
Write-Host ""
Write-Host ">>> PHASE 01/8 — ENVIRONMENT DETECT / DETEKCE" -ForegroundColor Cyan

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
        phases    = [ordered]@{ "0"="bootstrap"; "1"="environment-detect"; "2"="inventory-report"; "3"="repository-clone"; "4"="profile-identity"; "5"="package-setup"; "6"="environment-repair"; "7"="validation-test" }
        completed = @("0","1","2","3","4")
        next      = "5"
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
Write-Host ">>> 01 — environment-detect OK" -ForegroundColor Green
Write-Host "  fingerprint: $fingerprint, OS: $($osInfo.caption) build $($osInfo.build), tools: $(($tools.GetEnumerator() | Where-Object { $_.Value -ne $null } | Measure-Object).Count)/$($detectTools.Count) detected" -ForegroundColor DarkGray

# ═══ PHASE 02/8 — REPORT — uložit JSON + zobrazit status ═════
#         Výstup pro uživatele
$icon = @{ "new"="🔴"; "same"="🟢"; "os-changed"="🟠"; "tools-changed"="🟡" }
Write-Host ""
Write-Host ">>> PHASE 02/8 — INVENTORY REPORT / VÝSLEDEK" -ForegroundColor Cyan
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  $($icon[$status])  $($status.ToUpper())" -ForegroundColor White
foreach ($c in $changes) { Write-Host "║    $c" -ForegroundColor Yellow }
Write-Host "║" -ForegroundColor Cyan
Write-Host "║  REPO : $RepoUrl" -ForegroundColor Cyan
Write-Host "║  RPT  : $reportPath" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host ""
Write-Host ">>> 02 — inventory-report OK" -ForegroundColor Green
Write-Host "  status: $status, proceeding with phase 03" -ForegroundColor DarkGray

# ═══ PHASE 03/8 — CLONE — stáhnout repo (jen když git existuje) ═══
#         git clone → ~/.dev-env/repo/
if ($tools.git -ne $null) {
    Write-Host ""
    Write-Host ">>> PHASE 03/8 — REPOSITORY CLONE / KLONOVÁNÍ" -ForegroundColor Cyan
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
    Write-Host ">>> 03 — repository-clone OK" -ForegroundColor Green
    Write-Host "  repo at $RepoDir, proceeding with phase 04" -ForegroundColor DarkGray

    # ═══ PHASE 04/8 — PROFILE — detekce (home/work/lab) ═══════
    $profileScript = Join-Path $RepoDir "scripts\04-profile.ps1"
    if (Test-Path $profileScript) {
        Write-Host ""
        . $profileScript -WhatIf:$WhatIf
    }

    # ═══ PHASE 05/8 — SETUP (dry-run only) — když -WhatIf, automaticky ═══
    if ($WhatIf -and $ProfileName) {
        Write-Host ""
        Write-Host ">>> PHASE 05/8 — PACKAGE SETUP (dry-run) / SUCHÁ INSTALACE" -ForegroundColor Magenta
        $setupScript = Join-Path $RepoDir "scripts\05-setup-$ProfileName.ps1"
        if (Test-Path $setupScript) {
            & $setupScript -WhatIf
        } else {
            Write-Host "  ⚠ Setup script not found: 05-setup-$ProfileName.ps1" -ForegroundColor Yellow
            Write-Host "  Try manually: ./scripts/05-setup-home.ps1 -WhatIf" -ForegroundColor DarkCyan
        }
    }
} else {
    Write-Host ""
    Write-Host ">>> PHASE 03/8 — GIT NOT FOUND / GIT NENALEZEN — skipping" -ForegroundColor DarkYellow
    Write-Host "  Install git and run bootstrap again. / Nainstaluj git a spus bootstrap znovu." -ForegroundColor DarkYellow
    Write-Host ""
    Write-Host ">>> 03 — repository-clone FAIL" -ForegroundColor Red
    Write-Host "  git not available, cannot proceed with phases 04-07" -ForegroundColor DarkYellow
}

# ═══ RAW JSON — pro kopírování AI agentovi ═══════════════════
Write-Host ""
Write-Host $json
