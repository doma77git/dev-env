# 🔄 Workflow / Pracovní postupy

---

## 🆕 Nový stroj / New machine

```powershell
# Windows PS7 — hlavní pipeline
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex

# Windows PS5 — fallback (detekuje, doporučí, neinstaluje)
powershell -NoProfile -Command "irm https://gist.githubusercontent.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/00-bootstrap-fallback.ps1 | iex"

# Po pipeline:
cd ~/.dev-env/repo

# Zkontroluj profil
./scripts/40-profile.ps1

# Suchý běh instalace (ukáže co se bude instalovat)
./scripts/50-setup-home.ps1 -WhatIf

# Instaluj (s potvrzováním každého kroku)
./scripts/50-setup-home.ps1 -Confirm

# Nebo vše najednou (až budeš připraven)
./scripts/50-setup-home.ps1 -Force

# Oprav
./scripts/60-repair.ps1 -WhatIf
./scripts/60-repair.ps1 -Force

# Otestuj
./scripts/70-test.ps1
```

### Očekávaný výstup

```
╔══════════════════════════════════════════╗
║  PHASE 00 — CORE CHECK                   ║
╚══════════════════════════════════════════╝
  ✅  PowerShell 7.6.2 (Core)
  ✅  Git: git version 2.54.0.windows.1
  ✅  github.com reachable

╔══════════════════════════════════════════╗
║  PHASE 30 — REPOSITORY CLONE             ║
╚══════════════════════════════════════════╝
  Repo exists — pulling latest ...
  ✅  Pull complete

╔══════════════════════════════════════════╗
║  PHASE 10 — ENVIRONMENT DETECT           ║
╚══════════════════════════════════════════╝
  fingerprint: d924..., OS: Windows 11 Pro build 26200, tools: 8/13

╔══════════════════════════════════════════╗
║  PHASE 20 — INVENTORY REPORT             ║
╚══════════════════════════════════════════╝
  🟢  SAME
  REPO : https://github.com/doma77git/dev-env
  RPT  : C:\Users\...\.dev-env\report-*.json

╔══════════════════════════════════════════╗
║  PHASE 40 — PROFILE & IDENTITY           ║
╚══════════════════════════════════════════╝
  Profile  : 🏠 HOME — personal PC
  Git      : doma77 <doma77@outlook.cz> (saved)
  GitHub   : doma77git (logged in)
  SSH keys : 1 (rsa)

╔══════════════════════════════════════════╗
║  PHASE 50 — PACKAGE SETUP (home)        ║
╚══════════════════════════════════════════╝
  5.1 HOME: USERPROFILE (OK)
  5.2 Dirs: all OK
  5.3 Packages: 7z missing
  5.4 Symlinks: gitconfig → new
  5.5 Git identity: doma77 <...>
  5.6 Git autocrlf: not set → input

╔══════════════════════════════════════════╗
║  PHASE 60 — ENVIRONMENT REPAIR          ║
╚══════════════════════════════════════════╝
  [ISSUE] PATH duplicita: ... (x2)
  [ISSUE] PATH missing: ...
  [ISSUE] OneDrive redirect: Desktop

╔══════════════════════════════════════════╗
║  PHASE 70 — VALIDATION TEST             ║
╚══════════════════════════════════════════╝
  ✅  OS is Windows 10/11
  ✅  HOME is set
  ✅  Git installed
  ...
  ❌  PATH no duplicates
  ❌  OneDrive not redirecting Desktop/Documents
=== RESULT: 12 pass / 2 fail ===
```

### ⚠️ Varování

- **Nespouštěj `-Force` bez `-WhatIf`** — nejdřív suchý běh
- **Firemní stroj** — bootstrap detekuje `work` profil + safeMode
- **Server** — bootstrap detekuje `server` profil + safeMode
- **OneDrive** — `60-repair.ps1` varuje, pokud Desktop/Documents jsou v cloudu
- **Clone vždy běží** — i v dry-run režimu, protože je read-only

---

## 🔁 Existující stroj / Existing machine

```powershell
# 1. Bootstrap (detekuje změny)
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex

# 2. Menu → pull + volby
cd ~/.dev-env/repo
./menu/menu.ps1
```

---

## 🔄 Po reinstalaci / After reinstall

```powershell
# Bootstrap detekuje os-changed
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex

# Plná instalace
cd ~/.dev-env/repo
./scripts/50-setup-home.ps1 -Force
./scripts/60-repair.ps1 -Force
./scripts/link-configs.ps1 -Force
./scripts/70-test.ps1
```

---

## 🏢 Firemní stroj / Corporate machine

```powershell
# 1. Bootstrap — detekuje 🏢 work + safeMode
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex

# 2. Profil → work (auto, safeMode)
cd ~/.dev-env/repo
./scripts/40-profile.ps1

# 3. Review omezení
#    - safeMode = žádný auto-install
#    - vše musí být explicitně potvrzeno
#    - proxy konfigurace

# 4. Instalace — každý krok potvrdit
./scripts/50-setup-work.ps1 -WhatIf
./scripts/50-setup-work.ps1 -Force

# 5. Test
./scripts/70-test.ps1
```

### ⚠️ Firemní varování

- **safeMode** — žádný automatický install, vše musíš potvrdit
- **Firewall** — `winget` a `irm` mohou být blokované → použi PS5 fallback
- **Proxy** — `git`, `npm`, `pip` vyžadují proxy konfiguraci
- **GPO** — ExecutionPolicy může být vynucená → `Set-ExecutionPolicy -Scope Process`
- **VPN** — bez VPN nemusí fungovat interní zdroje

---

## 🧪 Lab VM / Test VM

```powershell
# Bootstrap detekuje VMware/VirtualBox → 🧪 lab
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex

# WSL, scoop, experimenty
cd ~/.dev-env/repo
./scripts/40-profile.ps1
./scripts/50-setup-lab.ps1 -WhatIf
./scripts/50-setup-lab.ps1 -Force
```

---

## 🔄 Sync / Synchronizace

```powershell
# Pull repa
cd ~/.dev-env/repo && git pull

# Push změny
cd ~/.dev-env/repo
git add -A
git commit -m "update"
git push

# Nebo přes menu:
./menu/menu.ps1 → [6] Sync
```
