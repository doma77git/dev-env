# Edge case ošetření

## E1 — PS5.1 (Windows PowerShell)

**Detekce:** Phase 00 (`00-core-check.ps1`)
**Reakce:** exit 1 + tisk příkazu (nikdy neinstaluje)
**Kód:**
```powershell
if ($psVer -lt 7) {
    Write-Host "  ❌  PowerShell $psVer — 7+ required" -ForegroundColor Red
    Write-Host "      winget install Microsoft.PowerShell" -ForegroundColor Cyan
    exit 1
}
```
**Důvod:** Pravidlo 3 z metapromptu — kritická závislost, bez PS7 nelze používat moderní konstrukty.

---

## E2 — Offline (gist/github nedostupný)

**Detekce:** Phase 00, connectivity check
**Reakce:** warning, pokračuje (clone/pull přeskočí)
**Kód:**
```powershell
try {
    $ping = Test-Connection "github.com" -Count 1 -Quiet -ErrorAction SilentlyContinue
    if (-not $ping) { Write-Host "  ⚠️  github.com unreachable (offline?)" -ForegroundColor Yellow }
} catch {
    Write-Host "  ⚠️  Connectivity check failed" -ForegroundColor Yellow
}
```
**Edge:** Proxy autodetekce není implementovaná — musíš nastavit ručně nebo spoléhat na systémový proxy.

---

## E3 — Git missing

**Detekce:** Phase 00 (`00-core-check.ps1`)
**Reakce:** exit 1 + doporučení (nikdy neinstaluje)
**Kód:**
```powershell
if (-not $gitCmd) {
    Write-Host "  ❌  Git not found / nenalezen" -ForegroundColor Red
    Write-Host "      Recommend: winget install Git.Git" -ForegroundColor Cyan
    Write-Host "      Download:  https://git-scm.com/downloads" -ForegroundColor DarkGray
    $criticalFails += "Git not found — clone phase requires it"
}
```

---

## E4 — Prázdný / poškozený klon

**Detekce:** Phase 30 — `Test-Path "$RepoDir\.git"` v `30-clone.ps1`
**Reakce:** Smaže `scripts/` a checkoutne z HEAD
**Kód:**
```powershell
if ((Test-Path $RepoDir) -and (Test-Path "$RepoDir\.git")) {
    git -C $RepoDir pull origin master
    # Force checkout — remove and recreate scripts/ to ensure new files
    Remove-Item -Path (Join-Path $RepoDir "scripts") -Recurse -Force -ErrorAction SilentlyContinue
    git -C $RepoDir checkout HEAD -- scripts/ 2>$null
} elseif (Test-Path $RepoDir) {
    # Broken repo — remove and reclone
    Remove-Item $RepoDir -Recurse -Force
    git clone -b master $RepoUrl $RepoDir
} else {
    git clone -b master $RepoUrl $RepoDir
}
```

---

## E5 — Headless (no console, pipe, CI)

**Detekce:** `Confirm-Action` interně
**Reakce:** timeout → skip (automaticky)
**Kód:**
```powershell
function Confirm-Action {
    $interactive = (-not [Console]::IsInputRedirected) -and [Environment]::UserInteractive
    if (-not $interactive) {
        Write-Host "  [HEADLESS] $Message -> SKIP"
        return $false
    }
    # ... 10s countdown ...
}
```

---

## E6 — Corrupted machines.json

**Detekce:** Phase 10 — `try { ConvertFrom-Json } catch {}`
**Reakce:** Ignorovat — začít s prázdnou historií
**Kód:**
```powershell
$machines = @()
if (Test-Path $machinesFile) {
    try { $machines = @(Get-Content $machinesFile -Raw | ConvertFrom-Json) } catch { $machines = @() }
    $machines = @($machines)
}
```

---

## E7 — Symlink bez admin práv

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

## E8 — OneDrive locked files / redirects

**Detekce:** Phase 10 — registry check
**Reakce:** Phase 60 repair varuje, nenapravuje automaticky
**Pravidlo:** Nikdy neměnit OneDrive nastavení bez potvrzení
```powershell
# 60-repair.ps1 — detection only
if ($v -and $v -match 'OneDrive') {
    Write-Host "[ISSUE] OneDrive redirects $n → $v" -ForegroundColor Yellow
    # Jen varování, žádná změna
}
```

---

## E9 — CI/CD mode (-Force without terminal)

**Detekce:** `-Force` přepínač
**Reakce:** Přeskočit všechny confirm dialogy (ShouldProcess)
```powershell
# V CI/CD: ShouldProcess s -Force = přeskočit dotazy
# setup/repair stále ukáže dry-run, pak rovnou apply
```

---

## E10 — Inkompatibilní previous report

**Detekce:** Phase 10 — `try/catch` kolem porovnání
**Reakce:** Nová detekce (status = new)
**Kód:**
```powershell
try {
    # Robust comparison — handles incompatible $previous
    $oldVal = try { $prevTools.$t } catch { $null }
} catch {
    Write-Host "  ⚠ Previous report format changed — treating as new detection" -ForegroundColor DarkYellow
    $status = "new"
}
```
