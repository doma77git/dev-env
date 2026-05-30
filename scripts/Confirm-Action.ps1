#!/usr/bin/env pwsh
# === scripts/Confirm-Action.ps1 ================================
function Confirm-Action {
    param([string]$Message, [int]$TimeoutSec=5, [string]$DefaultAnswer="N")
    $interactive = (-not [Console]::IsInputRedirected) -and [Environment]::UserInteractive -and ($null -ne $Host.UI)
    if (-not $interactive) {
        Write-Host "  [HEADLESS] $Message -> SKIP" -ForegroundColor DarkYellow
        return $false
    }
    $yn = if ($DefaultAnswer -eq "Y") { "Y/n" } else { "y/N" }
    Write-Host "  $Message [$yn] " -NoNewline -ForegroundColor Cyan
    Write-Host "($TimeoutSec`s) " -NoNewline -ForegroundColor DarkGray
    $end = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $end) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.KeyChar -eq "y" -or $key.KeyChar -eq "Y") { Write-Host " CONFIRMED" -ForegroundColor Green; return $true }
            if ($key.KeyChar -eq "n" -or $key.KeyChar -eq "N") { Write-Host " SKIPPED" -ForegroundColor Yellow; return $false }
        }
        Start-Sleep -Milliseconds 500
    }
    Write-Host " TIMEOUT -> SKIP" -ForegroundColor Yellow
    return $false
}
