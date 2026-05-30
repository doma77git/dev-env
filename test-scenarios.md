# Testovací scénáře — Pipeline v4

Cíl: ověřit, že žádná instalace neproběhne bez potvrzení.

---

## T1 — Suchý běh (dry-run)

```powershell
$env:DEV_ENV_WHATIF='1'
irm https://gist.github.com/doma77git/.../raw/bootstrap.ps1 | iex
```

**Očekávání:**
- Phase 00–70 všechny proběhnou
- Všechny fáze 40, 50, 60, 70 skončí po dry-run
- `[WHATIF]` nebo `(dry-run)` v každém výstupu
- ŽÁDNÉ změny na disku, žádné instalace, žádné nové složky

**Kontrola:**
```powershell
# Ověř, že se nic nezměnilo
ls ~/.dev-env/  # žádné nové soubory kromě report-*.json
```

---

## T2 — Interaktivní režim (bez -WhatIf, bez -Force)

```powershell
irm https://gist.github.com/doma77git/.../raw/bootstrap.ps1 | iex
```

**Očekávání:**
- Phase 01–30 proběhnou automaticky
- Phase 40: zobrazí dry-run → čeká na potvrzení `[y/N] (5s)`
- Phase 50: zobrazí dry-run → čeká na potvrzení
- Phase 60: zobrazí dry-run → čeká na potvrzení
- Phase 70: automatická (test)

**Test:** Nezmáčkni nic — timeout = skip.
- Ověř, že po 5s se přeskočí na další fázi.
- Ověř, že se nic nenainstalovalo.

---

## T3 — Force režim (CI/CD)

```powershell
irm https://gist.github.com/doma77git/.../raw/bootstrap.ps1 | iex
# nelze předat -Force přímo z irm, proto:
# lokálně:
./bootstrap.ps1 -Force
```

**Očekávání:**
- Phase 40: dry-run → přeskočit (NIKDY neinstalovat v CI bez explicitního --install)
- Phase 50: dry-run → přeskočit
- Phase 60: dry-run → přeskočit
- Phase 70: automatická

**POZNÁMKA:** `-Force` v CI neznamená "instaluj vše", ale "přeskoč všechny dotazy, proveď pouze read-only". Pro skutečnou instalaci v CI je potřeba explicitní přepínač `-Install`.

---

## T4 — PS5.1 (Windows PowerShell)

```powershell
# Otevři cmd a spusť:
powershell -NoProfile -Command "irm https://gist.github.com/.../raw/00-bootstrap-fallback.ps1 | iex"
```

**Očekávání:**
- Phase 02 detekuje PS5
- Zobrazí: "❌ Windows PowerShell 5 — 7+ required"
- Zobrazí: "winget install Microsoft.PowerShell"
- exit 1 → pipeline končí

**Test:** Neměla by proběhnout žádná další fáze.

---

## T5 — Bez gitu (HOME)

```powershell
# Na čistém stroji nebo dočasně odeber git z PATH
$env:PATH = $env:PATH -replace '.*Git[^;]*;', ''
irm ... | iex
```

**Očekávání:**
- Phase 30: dotaz "❓ Install Git?"
- Bez potvrzení: remote fallback
- S potvrzením: winget install Git.Git

**Test:** Nezmáčkni nic → timeout → remote fallback → pipeline pokračuje.

---

## T6 — Bez gitu (WORK/SERVER safeMode)

```powershell
# Simulace: vytvoř falešný profil
echo '{ "profile": "work" }' | Set-Content ~/.dev-env/config/profile.json

# Nebo nastav doménu:
# (nelze snadno bez domény — použij -Set work)
irm ... | iex
```

**Očekávání:**
- Phase 30: žádný dotaz, rovnou remote fallback
- "⚠ Git not available — using remote fallback"

---

## T7 — Offline

```powershell
# Odpoj internet / zablokuj gist
irm ... | iex
```

**Očekávání:**
- Phase 02: "❌ Cannot reach GitHub Gist"
- exit 1
- Žádné další fáze

---

## T8 — Opakovaný běh (re-run)

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
- Phase 15: "🟢 SAME"

---

## T9 — Verifikace že vše zůstalo read-only

Po jakémkoli běhu s `-WhatIf`:
```powershell
# Měl by být jen 1 nový report
$reports = Get-ChildItem ~/.dev-env/report-*.json | Sort-Object LastWriteTime -Descending
$reports[0]  # poslední report = nový

# Neměly by být nové složky
Test-Path ~\dev\projects\osobni  # false (pokud neexistovaly předtím)
Test-Path ~\.config\powershell    # false (pokud neexistovaly)
```
