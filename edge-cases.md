# Edge case ošetření

## E1 — PS5.1 (Windows PowerShell)

**Detekce:** Phase 02 (`02-core-check.ps1`)
**Reakce:** exit 1 + tisk příkazu
**Kód:**
```powershell
if ($psMajor -lt 7) {
    Write-Host "❌ Windows PowerShell $psVersion — 7+ required" -ForegroundColor Red
    Write-Host "DOPORUČENÍ: winget install Microsoft.PowerShell" -ForegroundColor Yellow
    exit 1
}
```
**Důvod:** Pravidlo 3 — kritická závislost, bez PS7 nelze používat `??`, `-Parallel`, `Invoke-Expression` s moderními konstrukty.

---

## E2 — Offline (gist nedostupný)

**Detekce:** Phase 02, connectivity check
**Reakce:** exit 1 + návod
**Kód:**
```powershell
try {
    $null = Invoke-WebRequest -Uri $gistTestUrl -Method Head -TimeoutSec 5 -ErrorAction Stop
} catch {
    Write-Host "❌ Cannot reach GitHub Gist" -ForegroundColor Red
    Write-Host "Zkontroluj proxy:"
    Write-Host "  `$env:HTTP_PROXY = 'http://proxy:port'"
    exit 1
}
```
**Edge:** Proxy autodetekce není implementovaná — musíš nastavit ručně nebo spoléhat na systémový proxy.

**Vylepšení (budoucí):**
```powershell
# Proxy autodetection for Phase 02
$proxyReg = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue
if ($proxyReg.ProxyServer -and -not $env:HTTP_PROXY) {
    $env:HTTP_PROXY = "http://$($proxyReg.ProxyServer)"
    $env:HTTPS_PROXY = "http://$($proxyReg.ProxyServer)"
}
```

---

## E3 — Git missing + HOME

**Detekce:** Phase 30 clone
**Reakce:** Dotaz "Chceš nainstalovat git?"
**Kód:**
```powershell
if (-not $gitCmd) {
    if ($safeMode) {
        # CORPORATE: remote fallback, no install
        Write-Host "⚠ Git not available — using remote fallback" -ForegroundColor Yellow
        $usingFallback = $true
    } else {
        # HOME: ask
        if (Confirm-Action "Install Git? (needed for local repo)" 5) {
            winget install Git.Git --accept-source-agreements
            # Re-check after install
            try { $gitCmd = Get-Command git -ErrorAction Stop } catch {}
        }
        if (-not $gitCmd) {
            Write-Host "Using remote fallback (limited functionality)" -ForegroundColor Yellow
            $usingFallback = $true
        }
    }
}
```

---

## E4 — Git missing + WORK/SERVER

**Detekce:** Phase 30 clone
**Reakce:** Warn → remote fallback → pokračovat
**Kód:**
```powershell
# WORK/SERVER = git optional, remote fallback OK
if (-not $gitCmd) {
    Write-Host "⚠ Git not available — using remote fallback" -ForegroundColor Yellow
    Write-Host "  Install later: winget install Git.Git" -ForegroundColor DarkGray
}
```

---

## E5 — Prázdný / poškozený klon

**Detekce:** Phase 30 clone — `Test-Path "$RepoDir\.git"`
**Reakce:** Smaže a znovu naklonuje (git) nebo stáhne ZIP
**Kód:**
```powershell
if (Test-Path $RepoDir) {
    if (-not (Test-Path "$RepoDir\.git")) {
        # Broken clone — remove and reclone
        Remove-Item $RepoDir -Recurse -Force
        git clone -b master $RepoUrl $RepoDir
    } else {
        git -C $RepoDir pull
    }
}
```

---

## E6 — Headless (no console, pipe, CI)

**Detekce:** `Confirm-Action` internally
**Reakce:** timeout → skip (automaticky)
**Kód:**
```powershell
function Confirm-Action {
    $interactive = (-not [Console]::IsInputRedirected) -and [Environment]::UserInteractive
    if (-not $interactive) {
        Write-Host "[HEADLESS] $Message → SKIP"
        return $false
    }
    # ... 5s countdown ...
}
```

---

## E7 — Corrupted machines.json

**Detekce:** Phase 10 — `try { ConvertFrom-Json } catch {}`
**Reakce:** Ignorovat — začít s prázdnou historií
**Kód:**
```powershell
if (Test-Path $machinesFile) {
    try { $machines = @(Get-Content $machinesFile -Raw | ConvertFrom-Json) } catch { $machines = @() }
}
```

---

## E8 — Symlink bez admin práv

**Detekce:** `link-configs.ps1` — `New-Item -ItemType SymbolicLink`
**Reakce:** Fallback na `Copy-Item`
**Kód:**
```powershell
try {
    New-Item -ItemType SymbolicLink -Path $to -Target $from -Force | Out-Null
} catch {
    Write-Host "  Symlink failed (need admin?) — fallback: Copy-Item" -ForegroundColor Yellow
    Copy-Item $from $to -Force
}
```

---

## E9 — OneDrive locked files / redirects

**Detekce:** Phase 10 — registry check
**Reakce:** 60-repair varuje, nenapravuje automaticky
**Pravidlo:** Nikdy neměnit OneDrive nastavení bez potvrzení
```powershell
if ($odRedirects.Count -gt 0) {
    Write-Host "⚠ OneDrive redirects: $($odRedirects.Keys -join ', ')" -ForegroundColor Yellow
    Write-Host "  Disable in: Settings → Backup → OneDrive folder backup" -ForegroundColor DarkGray
}
```

---

## E10 — CI/CD mode (-Force without terminal)

**Detekce:** `-Force` přepínač
**Reakce:** Přeskočit všechny confirm dialogy, použít výchozí hodnoty
```powershell
# V CI/CD: žádný interaktivní dotaz
if ($Force) {
    # Automaticky NE pro instalace, ANO pro read-only operace
    $proceed = $false  # nikdy neinstalovat v CI bez explicitního --install
}
```
