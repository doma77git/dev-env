# Testovací scénáře — Pipeline (00→30→10→20→40→50→60→70)

Cíl: ověřit, že žádná instalace neproběhne bez potvrzení.

---

## T1 — Suchý běh (dry-run)

```powershell
$env:DEV_ENV_WHATIF='1'
irm https://gist.github.com/doma77git/.../raw/bootstrap.ps1 | iex
```

**Očekávání:**
- Phase 00–70 všechny proběhnou
- Phase 30 clone proběhne (read-only)
- Phase 50, 60 zobrazí dry-run → confirm timeout → skip
- Phase 70 automatická
- ŽÁDNÉ změny na disku (kromě report-*.json)

**Kontrola:**
```powershell
ls ~/.dev-env/  # pouze report-*.json (žádné nové složky)
```

---

## T2 — Interaktivní režim (bez -WhatIf, bez -Force)

```powershell
irm https://gist.github.com/doma77git/.../raw/bootstrap.ps1 | iex
```

**Očekávání:**
- Phase 00–40 proběhnou automaticky
- Phase 50: zobrazí dry-run → čeká na potvrzení `[y/N] (10s)`
- Phase 60: zobrazí dry-run → čeká na potvrzení
- Phase 70: automatická

**Test:** Nezmáčkni nic → timeout = skip.
- Ověř, že po 10s se přeskočí na další fázi.
- Ověř, že se nic nenainstalovalo.

---

## T3 — Force režim (CI/CD)

```powershell
./bootstrap.ps1 -Force
```

**Očekávání:**
- Phase 50: dry-run → -Force přeskakuje confirm
- Phase 60: dry-run → -Force přeskakuje confirm
- Phase 70: automatická

---

## T4 — PS5.1 (Windows PowerShell)

```powershell
powershell -NoProfile -Command "irm https://gist.github.com/.../raw/00-bootstrap-fallback.ps1 | iex"
```

**Očekávání:**
- Fallback detekuje PS5
- Zobrazí: "❌ pwsh: NOT INSTALLED"
- Zobrazí: "winget install Microsoft.PowerShell"
- exit 1 → konec

**Test:** Neměla by proběhnout žádná instalace.

---

## T5 — Bez gitu

```powershell
# Dočasně odeber git z PATH
$env:PATH = $env:PATH -replace '.*Git[^;]*;', ''
irm https://gist.github.com/doma77git/.../raw/bootstrap.ps1 | iex
```

**Očekávání:**
- Phase 00: "❌ Git not found"
- "winget install Git.Git"
- exit 1

---

## T6 — Offline

```powershell
# Odpoj internet
irm https://gist.github.com/doma77git/.../raw/bootstrap.ps1 | iex
```

**Očekávání:**
- Phase 00: "⚠ github.com unreachable (offline?)"
- Warning, pokračuje dál
- Phase 30: clone/pull selže → exit 1

---

## T7 — Opakovaný běh (re-run)

```powershell
# Poprvé:
irm ... | iex

# Podruhé (hned poté):
$env:DEV_ENV_WHATIF='1'; irm ... | iex
```

**Očekávání:**
- Poprvé: status = new 🔴
- Podruhé: status = same 🟢
- Phase 10: "tools: N/13 detected" (stejné)
- Phase 20: "🟢 SAME"

---

## T8 — Verifikace že vše zůstalo read-only

Po jakémkoli běhu s `-WhatIf`:
```powershell
# Měl by být jen 1 nový report
$reports = Get-ChildItem ~/.dev-env/report-*.json | Sort-Object LastWriteTime -Descending
$reports[0]  # poslední report = nový

# Neměly by být nové složky
Test-Path ~\dev\projects\osobni  # false (pokud neexistovaly předtím)
Test-Path ~\.config\powershell    # false (pokud neexistovaly)
```
