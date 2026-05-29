#!/usr/bin/env pwsh
# === bootstrap.ps1 ============================================
# URL:    https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5
# ROLE:   Detect environment + point to repo + clone (if git)
#         Detekce prostředí + pointer na repo + clone (pokud git)
# RUN:    irm <url> | iex                                      (Windows)
# PARTNER: bootstrap.sh — curl -fsSL <url> | bash               (Linux/WSL)
# PATTERN: curl -fsSL <url>/bootstrap.sh | bash (dotfiles standard)
# ==============================================================

$RepoUrl  = "https://github.com/doma77git/dev-env"                # REPO — kam ukazuje gist
$RepoDir  = Join-Path $env:USERPROFILE ".dev-env/repo"         # LOCAL — kam se klonuje
$ErrorActionPreference = "Continue"                             # NEPADAT — pokračovat i při chybě

# ═══ 1. DETECT — inventura stroje (self‑contained, no git) ═══
#         Inventory — nepotřebuje git, vše je uvnitř
Write-Host ">>> DETECT / DETEKCE" -ForegroundColor Cyan

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
    $oldT = @(if ($previous.tools) { $previous.tools.PSObject.Properties | Where-Object { $_.Name -in $detectTools } } else { @() })
    $newT = $tools.PSObject.Properties | Where-Object { $_.Value -and $_.Name -in $detectTools -and -not ($oldT | Where-Object Name -eq $_.Name).Value }
    $lostT= $oldT | Where-Object { $_.Value -and $_.Name -in $detectTools -and -not ($tools.PSObject.Properties | Where-Object Name -eq $_.Name).Value }
    if ($newT -or $lostT) { 
        if ($status -ne "os-changed") { $status = "tools-changed" }
        if ($newT)  { $changes += "New: $($newT.Name -join ', ')" }
        if ($lostT) { $changes += "Gone: $($lostT.Name -join ', ')" }
    }
    if ($changes.Count -eq 0) { $status = "same" }               # nic se nezměnilo
}

# 1j. Report — sestavit JSON
#     Strukturovaný výstup pro AI i člověka
$report = [ordered]@{
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
$json = $report | ConvertTo-Json -Depth 5
$reportPath = Join-Path $envDir "report-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').json"
$json | Set-Content -Path $reportPath -Encoding UTF8
$machines += $report
$machines | ConvertTo-Json -Depth 5 | Set-Content -Path $machinesFile -Encoding UTF8

# ═══ 2. OUTPUT — status do konzole ═══════════════════════════
#         Výstup pro uživatele
$icon = @{ "new"="🔴"; "same"="🟢"; "os-changed"="🟠"; "tools-changed"="🟡" }
Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  $($icon[$status])  $($status.ToUpper())" -ForegroundColor White
foreach ($c in $changes) { Write-Host "║    $c" -ForegroundColor Yellow }
Write-Host "║" -ForegroundColor Cyan
Write-Host "║  REPO : $RepoUrl" -ForegroundColor Cyan
Write-Host "║  RPT  : $reportPath" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan

# ═══ 3. CLONE — stáhnout repo (jen když git existuje) ════════
#         git clone → ~/.dev-env/repo/
if ($tools.git -ne $null) {
    Write-Host ""
    Write-Host ">>> CLONE / KLONUJI REPO" -ForegroundColor Cyan
    if (Test-Path $RepoDir) {
        Write-Host "  Already exists / Repo existuje — pulling ..." -ForegroundColor Yellow
        try { git -C $RepoDir pull } catch { Write-Host "  Pull failed / selhal: $_" -ForegroundColor Red }
    } else {
        Write-Host "  git clone $RepoUrl $RepoDir" -ForegroundColor Yellow
        try { git clone $RepoUrl $RepoDir } catch { Write-Host "  Clone failed / selhal: $_" -ForegroundColor Red }
    }
    Write-Host "  Repo: $RepoDir" -ForegroundColor Green

    # ═══ 3a. PROFILE — detekce profilu (home/work/lab) ═══════
    $profileScript = Join-Path $RepoDir "scripts" "profile.ps1"
    if (Test-Path $profileScript) {
        Write-Host ""
        . $profileScript
    }
} else {
    Write-Host ""
    Write-Host ">>> GIT NOT FOUND / GIT NENALEZEN — skipping clone" -ForegroundColor DarkYellow
    Write-Host "  Install git and run bootstrap again. / Nainstaluj git a spus bootstrap znovu." -ForegroundColor DarkYellow
}

# ═══ 4. RAW JSON — pro kopírování AI agentovi ════════════════
Write-Host ""
Write-Host $json
