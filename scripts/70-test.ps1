#!/usr/bin/env pwsh
# === scripts/70-test.ps1 ======================================
# ROLE:   Validate environment — return 0 (pass) or 1 (fail)
#         Ověření prostředí
# RUN:    ./70-test.ps1
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

# 5. Node
$node = Get-Command node -ErrorAction SilentlyContinue
check "Node.js installed"                    ($node -ne $null) "winget install OpenJS.NodeJS.LTS"

# 6. Python
$python = Get-Command python -ErrorAction SilentlyContinue
check "Python installed"                     ($python -ne $null) "winget install Python.Python.3.12"

# 7. VS Code
check "VS Code installed"                    (Get-Command code -ErrorAction SilentlyContinue) "winget install Microsoft.VisualStudioCode"

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

# 13. OneDrive redirects — kontrola všech 5 systémových složek přes [Environment]::GetFolderPath()
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
