#!/usr/bin/env pwsh
# === scripts/10-detect.ps1 =====================================
# PHASE: 10 — Environment detect
# ROLE:  Full read-only inventory of the machine
#        fingerprint, OS, tools, PATH, OneDrive, corporate signals
# OUTPUT: $report (PSObject) — used by bootstrap.ps1 for JSON
#         + $status, $changes, $fingerprint
# RUN:   & ./10-detect.ps1
# =====================================================================
param([switch]$WhatIf)

$ErrorActionPreference = "Continue"

Write-Host ">>> PHASE 10 — ENVIRONMENT DETECT / DETEKCE" -ForegroundColor Cyan

# ─────────────────────────────────────────────────────────────────
# 10.1 — Output dir
# ─────────────────────────────────────────────────────────────────
$envDir = Join-Path $env:USERPROFILE ".dev-env"
if (-not (Test-Path $envDir)) { $null = New-Item -ItemType Directory -Path $envDir -Force }

# ─────────────────────────────────────────────────────────────────
# 10.2 — Fingerprint
# ─────────────────────────────────────────────────────────────────
$hostname  = $env:COMPUTERNAME
$username  = $env:USERNAME
$domain    = $env:USERDOMAIN
$fingerprint = -join (([Security.Cryptography.SHA256]::Create().ComputeHash(
    [Text.Encoding]::UTF8.GetBytes("$hostname|$username|$domain")
)) | ForEach-Object { $_.ToString("x2") })

# ─────────────────────────────────────────────────────────────────
# 10.3 — Cache (machines.json)
# ─────────────────────────────────────────────────────────────────
$machinesFile = Join-Path $envDir "machines.json"
$machines = @()
if (Test-Path $machinesFile) {
    try { $machines = @(Get-Content $machinesFile -Raw | ConvertFrom-Json) } catch {}
    $machines = @($machines)
}
$previous = $machines | Where-Object { $_.fingerprint -eq $fingerprint } | Select-Object -Last 1

# ─────────────────────────────────────────────────────────────────
# 10.4 — OS
# ─────────────────────────────────────────────────────────────────
$os  = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
$cs  = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
$osInfo = [ordered]@{
    caption     = $os.Caption
    build       = $os.BuildNumber
    arch        = $os.OSArchitecture
    installDate = ([DateTime]$os.InstallDate).ToString("yyyy-MM-dd")
    lastBoot    = ([DateTime]$os.LastBootUpTime).ToString("yyyy-MM-dd")
}

# ─────────────────────────────────────────────────────────────────
# 10.5 — Tools
# ─────────────────────────────────────────────────────────────────
$detectTools = @("git","node","python","code","winget","docker","gh","pwsh","curl","7z","nvim","scoop","nvm")
$tools = [ordered]@{}
foreach ($t in $detectTools) {
    $cmd = Get-Command $t -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) {
        $ver = try { (& $t --version 2>&1 | Select-Object -First 1) -join ' ' } catch { "?" }
        $tools[$t] = "$ver | $($cmd.Source)"
    } else { $tools[$t] = $null }
}

# ─────────────────────────────────────────────────────────────────
# 10.6 — PATH
# ─────────────────────────────────────────────────────────────────
$pathEntries = $env:PATH -split ';' | Where-Object { $_ -ne '' }
$pathErrors = @()
if ($pathEntries.Count -gt 50) { $pathErrors += "Count: $($pathEntries.Count)" }
$pathErrors += $pathEntries | Group-Object | Where-Object Count -gt 1 | ForEach-Object { "DUP: $($_.Name)" }
$pathErrors += $pathEntries | Where-Object { 
    try { -not (Test-Path ([Environment]::ExpandEnvironmentVariables($_))) } catch { $true }
} | ForEach-Object { "MISS: $_" }

# ─────────────────────────────────────────────────────────────────
# 10.7 — OneDrive
# ─────────────────────────────────────────────────────────────────
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

# ─────────────────────────────────────────────────────────────────
# 10.8 — Corporate
# ─────────────────────────────────────────────────────────────────
$corp = [ordered]@{
    domainJoined = $cs.PartOfDomain
    domain       = $cs.Domain
    manufacturer = $cs.Manufacturer
    model        = $cs.Model
    proxy        = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue).ProxyServer
}

# ─────────────────────────────────────────────────────────────────
# 10.9 — Status (new / same / os-changed / tools-changed)
# ─────────────────────────────────────────────────────────────────
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

# ─────────────────────────────────────────────────────────────────
# 10.10 — Build report object
# ─────────────────────────────────────────────────────────────────
$RepoUrl = "https://github.com/doma77git/dev-env"
$report = [ordered]@{
    pipeline = [ordered]@{
        phases    = [ordered]@{ "00"="bootstrap"; "01"="profile"; "02"="core-check"; "10"="environment-detect"; "15"="inventory-report"; "20"="repository-clone"; "30"="profile-identity"; "40"="essentials-setup"; "50"="categories-setup"; "60"="environment-repair"; "70"="validation-test" }
        completed = @("00","01","02")
        next      = "10"
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

# ─────────────────────────────────────────────────────────────────
# 10.11 — Save report
# ─────────────────────────────────────────────────────────────────
$json = $report | ConvertTo-Json -Depth 6
$reportPath = Join-Path $envDir "report-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').json"
$json | Set-Content -Path $reportPath -Encoding UTF8
$machines += $report
$machines | ConvertTo-Json -Depth 6 | Set-Content -Path $machinesFile -Encoding UTF8

Write-Host ""
Write-Host ">>> 10 — environment-detect OK" -ForegroundColor Green
Write-Host "  fingerprint: $fingerprint, OS: $($osInfo.caption) build $($osInfo.build), tools: $(($tools.GetEnumerator() | Where-Object { $_.Value -ne $null } | Measure-Object).Count)/$($detectTools.Count) detected" -ForegroundColor DarkGray

# Return report to caller (bootstrap.ps1)
$report
$json
