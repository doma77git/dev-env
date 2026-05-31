#!/usr/bin/env pwsh
# === scripts/70-test.ps1 ======================================
# ROLE:   Validate environment — 16 checks, exit 0 (pass) or 1 (fail)
#         Ověření prostředí — 16 kontrol
# RUN:    ./70-test.ps1
# INPUT:  None (reads env vars, PATH, registry)
# OUTPUT: Exit code 0=all pass, 1=some fail
#         Console output with ✅/❌ per check
# ==============================================================
$ErrorActionPreference = "Continue"
$pass = 0; $fail = 0

Write-Host ">>> PHASE 70 — VALIDATION TEST / OVĚŘENÍ" -ForegroundColor Green
Write-Host ""

function check($label, $condition, $fix) {
    if ($condition) {
        Write-Host "  ✅  $label" -ForegroundColor Green
        $script:pass++
    } else {
        Write-Host "  ❌  $label" -ForegroundColor Red
        if ($fix) { Write-Host "      Fix: $fix" -ForegroundColor DarkCyan }
        $script:fail++
    }
}

# Detekce s fallbackem na Program Files (pro appky ne v PATH)
function Test-AppInstalled($name, $paths) {
    if (Get-Command $name -ErrorAction SilentlyContinue) { return $true }
    foreach ($p in $paths) { if (Test-Path $p) { return $true } }
    return $false
}

# 1. OS
check "OS is Windows 10/11"                  ($env:OS -eq "Windows_NT")

# 2. HOME
check "HOME is set"                           ($env:HOME -ne $null)

# 3. .dev-env
check "~/.dev-env/ exists"                   (Test-Path "$env:USERPROFILE\.dev-env")

# 4. Git
$git = Get-Command git -ErrorAction SilentlyContinue
check "Git installed"                         ($git -ne $null) "winget install Git.Git"
if ($git) {
    check "Git user.name"                     (git config --global user.name 2>$null) "git config --global user.name"
    check "Git user.email"                    (git config --global user.email 2>$null) "git config --global user.email"
}

# 5. Node (s fallbackem na Program Files)
$nodePaths = @("$env:ProgramFiles\nodejs\node.exe", "${env:ProgramFiles(x86)}\nodejs\node.exe")
check "Node.js installed"                    (Test-AppInstalled node $nodePaths) "winget install OpenJS.NodeJS.LTS"

# 6. Python (s fallbackem na Program Files)
$pyPaths = @("$env:ProgramFiles\Python312\python.exe", "$env:ProgramFiles\Python313\python.exe", "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe")
check "Python installed"                     (Test-AppInstalled python $pyPaths) "winget install Python.Python.3.12"

# 7. VS Code (s fallbackem na Program Files)
$codePaths = @("$env:ProgramFiles\Microsoft VS Code\Code.exe", "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe")
check "VS Code installed"                    (Test-AppInstalled code $codePaths) "winget install Microsoft.VisualStudioCode"

# 8. PATH — per-scope analýza
$sysPathRaw = [Environment]::GetEnvironmentVariable("PATH", "Machine")
$usrPathRaw = [Environment]::GetEnvironmentVariable("PATH", "User")
$sysEntries = if ($sysPathRaw) { $sysPathRaw -split ';' | Where-Object { $_ -ne '' } } else { @() }
$usrEntries = if ($usrPathRaw) { $usrPathRaw -split ';' | Where-Object { $_ -ne '' } } else { @() }
$totalEntries = ($env:PATH -split ';' | Where-Object { $_ -ne '' }).Count

check "PATH total < 50 entries ($totalEntries)" ($totalEntries -le 50)

# 9. PATH duplicity per scope
$sysDupes = $sysEntries | Group-Object | Where-Object Count -gt 1
$usrDupes = $usrEntries | Group-Object | Where-Object Count -gt 1
$crossDupes = @()
foreach ($s in $sysEntries) { $sNorm = $s.TrimEnd('\')
    foreach ($u in $usrEntries) { if ($sNorm -eq $u.TrimEnd('\')) { $crossDupes += $sNorm; break } } }
$crossDupes = $crossDupes | Select-Object -Unique

$dupDetail = @()
if ($sysDupes.Count -gt 0) { $dupDetail += "System:$($sysDupes.Count)" }
if ($usrDupes.Count -gt 0) { $dupDetail += "User:$($usrDupes.Count)" }
if ($crossDupes.Count -gt 0) { $dupDetail += "Cross:$($crossDupes.Count)" }
$dupFix = if ($dupDetail.Count -gt 0) {
    "repair.ps1 -Force ($($dupDetail -join ', '))"
} else { "repair.ps1 -Force" }

$pathDupOk = ($sysDupes.Count -eq 0 -and $usrDupes.Count -eq 0 -and $crossDupes.Count -eq 0)
check "PATH no duplicates ($($dupDetail -join ', '))" $pathDupOk $dupFix

# 10. SSH dir
check "~/.ssh/ exists"                       (Test-Path "$env:USERPROFILE\.ssh") "mkdir ~/.ssh"

# 11. SSH key
$keys = Get-ChildItem "$env:USERPROFILE\.ssh\id_*" -ErrorAction SilentlyContinue
check "SSH key exists"                       ($keys.Count -gt 0) "ssh-keygen -t ed25519"

# 12. Profile JSON integrity
$profilesDir = Join-Path $PSScriptRoot ".." "profiles"
$profilesOk = $true
if (Test-Path $profilesDir) {
    Get-ChildItem "$profilesDir/*.json" | ForEach-Object {
        try {
            $p = Get-Content $_.FullName -Raw | ConvertFrom-Json
            if ($_.BaseName -ne "base" -and -not $p.extends) { $profilesOk = $false }
            if (-not $p.identity) { $profilesOk = $false }
        } catch { $profilesOk = $false }
    }
}
check "Profile JSONs valid"                  $profilesOk "Validate profiles/*.json syntax"

# 13. Required packages installed
$reqPkgs = @("git","pwsh")
$reqOk = $true
$reqMissing = @()
foreach ($pkg in $reqPkgs) {
    if (-not (Get-Command $pkg -ErrorAction SilentlyContinue)) {
        $reqOk = $false; $reqMissing += $pkg
    }
}
$reqFix = if ($reqMissing.Count -gt 0) {
    "Chybí: $($reqMissing -join ', ') — spustit: .\scripts\50-setup-home.ps1 -IncludeRequired"
} else { "Install required packages" }
check "Required packages installed ($($reqPkgs.Count - $reqMissing.Count)/$($reqPkgs.Count))" $reqOk $reqFix

# 14. Recommended — reasonix (pokud je nainstalovaný)
$reasonixOk = Test-AppInstalled reasonix @("$env:LOCALAPPDATA\Programs\Reasonix\reasonix.exe", "$env:ProgramFiles\Reasonix\reasonix.exe")
check "Reasonix installed"                   $reasonixOk "winget install Reasonix.Reasonix"

# 15. OneDrive redirects — kontrola všech 5 systémových složek přes [Environment]::GetFolderPath()
$odOk = $true
$odRedirected = @()
$odCheckFolders = @{
    "Desktop"   = @{ api = "Desktop";    cz = "Plocha" }
    "Documents" = @{ api = "MyDocuments"; cz = "Dokumenty" }
    "Pictures"  = @{ api = "MyPictures"; cz = "Obrázky" }
    "Music"     = @{ api = "MyMusic";    cz = "Hudba" }
    "Videos"    = @{ api = "MyVideos";   cz = "Videa" }
}
foreach ($key in $odCheckFolders.Keys) {
    $info = $odCheckFolders[$key]
    $resolvedPath = [Environment]::GetFolderPath($info.api)
    if ($resolvedPath -match 'OneDrive') {
        $odOk = $false
        $odRedirected += $info.cz
    }
}
$odFixMsg = if ($odRedirected.Count -gt 0) {
    $odList = $odRedirected -join ', '
    "OneDrive zalohuje: $odList — spustit: .\scripts\60-repair.ps1 -Force"
} else {
    "Turn off OneDrive backup"
}
check "OneDrive not redirecting system folders" $odOk $odFixMsg

# Summary
Write-Host ""
Write-Host ""
Write-Host ">>> 70 — validation-test $($(if ($fail -eq 0) { "OK" } else { "FAIL" }))" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Red" })
Write-Host "  $pass pass / $fail fail" -ForegroundColor $(if ($fail -eq 0) { "DarkGray" } else { "Red" })
Write-Host "=== RESULT: $pass pass / $fail fail ===" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Red" })
exit $(if ($fail -eq 0) { 0 } else { 1 })
