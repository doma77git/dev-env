#!/usr/bin/env pwsh
# === menu/menu.ps1 ============================================
# ROLE:   Interactive terminal menu / interaktivní menu
# RUN:    ./menu.ps1   (z repa:  ~/.dev-env/repo/menu/menu.ps1)
# ==============================================================

$repoDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

Clear-Host
while ($true) {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║            🧰  DEV-ENV MENU               ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║                                            ║"
    Write-Host "║  [1] 🏠  Profile       / Profil           ║"
    Write-Host "║  [2] 🔍  Setup (dry-run) / Instalace nasucho ║"
    Write-Host "║  [3] 🔧  Repair        / Opravy           ║"
    Write-Host "║  [4] ✅  Test          / Testy            ║"
    Write-Host "║  [5] 📄  Report        / Report           ║"
    Write-Host "║  [6] 🔄  Sync          / Synchronizace    ║"
    Write-Host "║  [7] 📖  Docs          / Dokumentace      ║"
    Write-Host "║  [8] 🌐  Open repo     / Otevřít repo     ║"
    Write-Host "║                                            ║"
    Write-Host "║  [Q] 🚪  Exit          / Konec            ║"
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    $choice = Read-Host "  Choice / Volba"
    Write-Host ""

    switch ($choice) {
        "1" { & "$repoDir\scripts\40-profile.ps1" }
        "2" { & "$repoDir\scripts\50-setup-home.ps1" -WhatIf }
        "3" { & "$repoDir\scripts\60-repair.ps1" -WhatIf }
        "4" { & "$repoDir\scripts\70-test.ps1" }
        "5" { 
            $latest = Get-ChildItem "$env:USERPROFILE\.dev-env\report-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($latest) { Get-Content $latest.FullName -Raw } else { Write-Host "  No report / žádný report" }
        }
        "6" { 
            Write-Host "  Pulling repo ..."
            git -C $repoDir pull
        }
        "7" { 
            Write-Host "  Docs: $repoDir\docs\index.md"
            if (Get-Command code -ErrorAction SilentlyContinue) { code "$repoDir\docs\index.md" }
        }
        "8" { 
            $url = (git -C $repoDir remote get-url origin)
            Start-Process $url
        }
        "Q" { Write-Host "Bye. / Čau."; break }
        "q" { Write-Host "Bye. / Čau."; break }
        default { Write-Host "  Invalid / neplatná volba" }
    }
}
