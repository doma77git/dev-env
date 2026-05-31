# 🧰 dev-env — Pipeline

> ⚡ **Jeden řádek pro kompletní vývojářské prostředí**  
> `irm https://raw.githubusercontent.com/doma77git/dev-env/master/bootstrap.ps1 | iex`

| Kategorie | Stav |
|-----------|------|
| 🔴 Required | ✅ git, pwsh, wt |
| 🟡 Recommended | ✅ code, 7z, chrome, notepad++, gh, curl, reasonix |
| 🟢 Optional | ☐ nvim, docker, starship |
| 🔵 Dev | ☐ node, python, vs2022, rider, postman |

---

## 🚀 Quick Start

```powershell
# Celý pipeline najednou
irm https://raw.githubusercontent.com/doma77git/dev-env/master/bootstrap.ps1 | iex

# Nebo lokálně
cd C:\Users\spravce\.dev-env\repo
.\scripts\00-menu.ps1
.\scripts\00-menu.ps1 -WhatIf   # suchý běh
.\scripts\20-install-software.ps1 -IncludeRequired -Force
.\scripts\70-test.ps1
```

---

> One command. Full inventory. All machines.  
> Jeden příkaz. Plná inventura. Všechny stroje.

---

## 🚦 KDO JSI? ČTI TOTO:

| Jsi... | Čti... |
|---|---|
| 👤 **Člověk — chci pochopit** | [`docs/index.md`](docs/index.md) |
| 👤 **Člověk — chci spustit** | [`docs/workflows.md`](docs/workflows.md) |
| 👤 **Člověk — chci znát strukturu** | [`docs/architecture.md`](docs/architecture.md) |
| 🤖 **AI agent — chci všechen kontext** | [`ai/context.md`](ai/context.md) |
| 🤖 **AI agent — chci jen schéma dat** | [`ai/schema.json`](ai/schema.json) |
| ⚙️ **Script / CI — chci data o projektu** | [`manifest.json`](manifest.json) |

---

## ⚡ Rychlý start

```powershell
# Windows (PowerShell 7+) — ostrý run
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex

# Windows — dry-run (detekce + náhled, nic se neinstaluje)
$env:DEV_ENV_WHATIF='1'; irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex

# Windows PS5 — fallback (detekuje, doporučí, neinstaluje)
powershell -NoProfile -Command "irm https://gist.githubusercontent.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/00-bootstrap-fallback.ps1 | iex"
```

```bash
# Linux / WSL (bash)
curl -fsSL https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.sh | bash
```

### Co uvidíš

```
╔══════════════════════════════════════════╗
║  PHASE 00 — CORE CHECK                   ║
╚══════════════════════════════════════════╝
00.1 PowerShell version
  ✅  PowerShell 7.6.2 (Core)
00.2 Git
  ✅  Git: git version 2.54.0.windows.1
00.3 Network connectivity
  ✅  github.com reachable
─── CORE CHECK SUMMARY ────────────────────────
  ✅  All prerequisites OK

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
```

---

## 🔄 Co se stane

```
irm | iex
  ├─ PS7 ──▶ 00→30→10→20→40→50→60→70
  └─ PS5 ──▶ 00-bootstrap-fallback → detect→recommend→exit
```

| Fáze | Skript | Popis |
|---|---|---|
| **00. Core check** | `scripts/00-core-check.ps1` | PS7, git, connectivity — exit 1 při chybě, nikdy neinstaluje |
| **30. Clone** | `scripts/30-clone.ps1` | git clone/pull (vždy běží = read-only) |
| **10. Detect** | `scripts/10-detect.ps1` | Fingerprint, OS, 13 nástrojů, PATH, OneDrive |
| **20. Report** | `scripts/20-report.ps1` | JSON → `~/.dev-env/report-*.json` + `machines.json` |
| **40. Profile** | `scripts/40-profile.ps1` | home / work / lab / server, git identity, GitHub, SSH |
| **50. Setup** | `scripts/50-setup-{profile}.ps1` | Balíčky, složky, git config, autocrlf (ShouldProcess) |
| **60. Repair** | `scripts/60-repair.ps1` | PATH, HOME, OneDrive, SSH (ShouldProcess) |
| **70. Test** | `scripts/70-test.ps1` | 14 kontrol — exit 0 = pass |
| **Menu** | `menu/menu.ps1` | Interaktivní rozcestník |

---

## ⚠️ DŮLEŽITÉ — varování

| Varování | Vysvětlení |
|---|---|
| 🔒 **Nikdy necommituj `~/.ssh/`** | SSH klíče = tvé digitální otisky. Únik = kompromitace všech serverů. |
| 🔒 **Nikdy necommituj `machines.json`** | Obsahuje hostname, username, doménu, cesty — recon sen pro útočníka. Je to lokální historie. |
| 🟡 **Bez gitu = bez clone** | Bootstrap detekci zvládne bez gitu. Ale repo se neklonuje → `scripts/` nebudou dostupné. Nainstaluj git a spusť bootstrap znovu. |
| 🟡 **PS5 = fallback** | `00-bootstrap-fallback.ps1` detekuje → doporučí → skončí. Žádná auto‑instalace. |
| 🟡 **Firemní stroj = omezení** | GPO může blokovat `irm`, `iex`, `winget`. Bootstrap to detekuje — použi `work` profil. |
| 🔵 **OneDrive přesměrování** | Bootstrap detekuje, `60-repair.ps1` varuje. Desktop v OneDrive = každý screenshot se syncuje do cloudu. |

---

## 📂 Adresářová struktura (dvě místa)

```
📁 PRACOVNÍ (zdrojový kód)
   C:\Projects\dotazy\           ← kde edituješ, commituješ
   └── ai/ docs/ scripts/ ...

📁 RUNTIME (kam bootstrap instaluje)
   ~\.dev-env\
   ├── machines.json             ← historie VŠECH detekcí (append-only, lokální)
   ├── report-*.json             ← poslední report (pro AI)
   ├── config/
   │   └── profile.json          ← uložený profil (home/work/lab)
   └── repo/                     ← git clone repa (sem chodíš pro scripts/)
       ├── bootstrap.ps1
       ├── scripts/
       │   ├── 00-core-check.ps1        ← detekce závislostí (žádná instalace)
       │   ├── 00-bootstrap-fallback.ps1← PS5 fallback
       │   ├── 10-detect.ps1            ← inventura
       │   ├── 20-report.ps1            ← report + JSON
       │   ├── 30-clone.ps1             ← clone/pull
       │   ├── 40-profile.ps1           ← profil + identity
       │   ├── 50-setup-home.ps1        ← home instalace
       │   ├── 50-setup-lab.ps1         ← VM instalace
       │   ├── 50-setup-work.ps1        ← firemní instalace
       │   ├── 60-repair.ps1            ← opravy
       │   ├── 70-test.ps1              ← validace
       │   ├── Confirm-Action.ps1       ← potvrzovací dialog
       │   └── link-configs.ps1         ← symlinky
       ├── menu/menu.ps1
       ├── ai/ docs/ profiles/
       └── ...
```

---

## 🧪 První kroky po instalaci

```powershell
# 1. Dry-run — detekce + profil + náhled (nic se neinstaluje)
$env:DEV_ENV_WHATIF='1'
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex

# 2. Ostrý run — detekce + pull + profil (uloží se)
Remove-Item Env:\DEV_ENV_WHATIF -ErrorAction SilentlyContinue
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex

# 3. Přejdi do naklonovaného repa
cd ~/.dev-env/repo

# 4. Zkontroluj profil
./scripts/40-profile.ps1

# 5. Suchý běh instalace
./scripts/50-setup-home.ps1 -WhatIf

# 6. Instaluj (s potvrzováním každého kroku -Confirm nebo vše najednou -Force)
./scripts/50-setup-home.ps1 -Confirm   # každý krok se ptá
./scripts/50-setup-home.ps1 -Force     # vše najednou

# 7. Oprav problémy
./scripts/60-repair.ps1 -WhatIf
./scripts/60-repair.ps1 -Force

# 8. Otestuj
./scripts/70-test.ps1

# 9. Otevři menu
./menu/menu.ps1
```

---

## 🔧 Troubleshooting

| Problém | Řešení |
|---|---|
| `irm` selže (TLS/SSL) | Spusť `[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12` ručně. Bootstrap to dělá automaticky, ale PowerShell 5.1 může selhat dřív. |
| `iex` blokováno (ExecutionPolicy) | `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` — jen pro aktuální okno. |
| `git clone` selže | Zkontroluj `git --version`. Není-li git: `winget install Git.Git`. Za proxy: `git config --global http.proxy http://proxy:8080`. |
| `winget` nefunguje | Na firemním stroji může být blokovaný. Použij `work` profil (žádný winget). |
| `New-Item` symlink selže | Symlinky na Windows vyžadují admin práva (nebo Developer Mode). `link-configs.ps1` fallbackuje na `Copy-Item`. |
| Report ukazuje `Gone: git, node, ...` | `machines.json` má starý záznam z buggy verze. Smaž `~/.dev-env/machines.json` a spusť bootstrap znovu. |
| Duplicitní reporty v `machines.json` | Bootstrap appenduje při každém spuštění. Jednou za čas smaž staré záznamy (nebo celý soubor). |

---

## 📂 Soubory — k čemu jsou

| Soubor | Pro koho | Účel |
|---|---|---|
| `bootstrap.ps1` / `.sh` | 🔧 Spustit | Entry point — orchestrátor (00→30→10→20→40→50→60→70) |
| `manifest.json` | ⚙️ Stroj | Autoritativní data: verze, timestamp, seznam souborů |
| `ai/context.md` | 🤖 AI | Kompletní kontext: lifecycle, rozhodování, prompty, OS logika |
| `ai/schema.json` | 🤖 AI | JSON Schema reportu |
| `docs/index.md` | 👤 Člověk | Landing page (GitHub Pages) |
| `docs/architecture.md` | 👤 Člověk | Jak to funguje |
| `docs/workflows.md` | 👤 Člověk | Krok za krokem |
| `index.html` | 👤 Offline | Lokální landing (otevři v prohlížeči) |
| `profiles/*.json` | ⚙️ Stroj | Definice home / work / lab |
| `scripts/00-core-check.ps1` | 🔧 Spustit | Detekce PS7, git, connectivity |
| `scripts/10-detect.ps1` | 🔧 Spustit | Inventura prostředí |
| `scripts/20-report.ps1` | 🔧 Spustit | Zobrazení + uložení JSON |
| `scripts/30-clone.ps1` | 🔧 Spustit | Git clone/pull |
| `scripts/40-profile.ps1` | 🔧 Spustit | Detekce profilu home/work/lab |
| `scripts/50-setup-home.ps1` | 🔧 Spustit | Home PC — winget, dirs, git, autocrlf |
| `scripts/50-setup-work.ps1` | 🔧 Spustit | Corporate PC — proxy, VPN, manual |
| `scripts/50-setup-lab.ps1` | 🔧 Spustit | Lab VM — WSL, scoop, experimental |
| `scripts/60-repair.ps1` | 🔧 Spustit | Opravy PATH, HOME, OneDrive, SSH |
| `scripts/70-test.ps1` | 🔧 Spustit | 14 kontrol, exit 0 = pass |
| `scripts/link-configs.ps1` | 🔧 Spustit | Symlink konfigů z repa |
| `configs/*` | 🔧 Spustit | Sdílené konfigy (git, pwsh) |
| `menu/menu.ps1` | 🔧 Spustit | Interaktivní menu |

---

## 🗺️ Odkazy

| Kam | URL |
|---|---|
| 🔩 Repo | [github.com/doma77git/dev-env](https://github.com/doma77git/dev-env) |
| ⚡ Gist | [gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5](https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5) |
| 🌐 Pages | [doma77git.github.io/dev-env](https://doma77git.github.io/dev-env) |

---

## 🔄 Sync — co se kam synchronizuje

| Data | Kam | Jak | Frekvence |
|---|---|---|---|
| `bootstrap.ps1/.sh` | Gist | Manuální kopie z repa | Při změně |
| Repo | GitHub | `git push/pull` | Podle potřeby |
| `~/.dev-env/repo/` | Lokální klon | `git pull` (bootstrap nebo menu) | Při spuštění |
| `~/.dev-env/machines.json` | **Jen lokálně** | Nikdy nesyncovat | — |
| `~/.dev-env/config/` | **Jen lokálně** | Nikdy nesyncovat | — |
| `~/.ssh/` | **Jen lokálně** | Nikdy nesyncovat | — |
| Konfigy (`~/.gitconfig`, ...) | Symlink z repa | `link-configs.ps1` | Po setupu |

---

## ✅ Hotovo / 🟠 TODO

| Stav | Co |
|---|---|
| ✅ | Bootstrap orchestrátor — 00→30→10→20→40→50→60→70 |
| ✅ | 00-core-check.ps1 — PS7, git, connectivity (žádná instalace) |
| ✅ | 30-clone.ps1 — vždy běží i v dry-run (read-only) |
| ✅ | 10-detect.ps1 — inventura (oddělená z bootstrap.ps1) |
| ✅ | 20-report.ps1 — zobrazení + JSON (oddělená) |
| ✅ | Profily — base, home, work, lab, server + auto-detekce |
| ✅ | Identita — auto-detekce z git configu (uložena v identity.json) |
| ✅ | GitHub + SSH detekce v profilu |
| ✅ | safeMode — corporate/server = no auto-install |
| ✅ | ShouldProcess — -WhatIf, -Confirm na setup/repair |
| ✅ | `scripts/00-bootstrap-fallback.ps1` — PS5 fallback, bez instalace |
| ✅ | `scripts/Confirm-Action.ps1` — 10s timeout, headless detect |
| ✅ | Deep merge v `40-profile.ps1` — rekurzivní merge profilů |
| ✅ | Porovnávač tools — robustní, žádné falešné "Gone" |
| ✅ | `bootstrap.sh` — Linux/WSL orchestrátor (00→30→10→20→40→50) + WhatIf |
| ✅ | GPG commit signing — detekce v 40-profile.ps1 pro work/server |
| ✅ | Rollback — transcript logging + `scripts/undo-last.ps1` |
| ✅ | CI/CD — `.github/workflows/ci.yml` + `pr.yml` + `gist-sync.yml` |
| ✅ | Profile validace — kontrola `extends`/`identity`/`safeMode` |
| ✅ | `scripts/50-setup-server.ps1` — headless server instalace |
| ✅ | Secrets deduplikace — kanonický seznam v `profiles/base.json#/secrets` |
| 🟠 | Interaktivní režim v setup-*.ps1 (výběr packages) |
| 🟠 | SSH keygen prompt v setupu (když chybí klíče) |

---

## ⚠️ Co se nikdy nesyncuje

> Kanonický seznam: [`profiles/base.json#/secrets`](profiles/base.json) — jediný zdroj pravdy.

| Složka | Důvod |
|---|---|
| `~/.ssh/` | SSH klíče — digitální otisky |
| `~/.dev-env/machines.json` | Lokální historie detekcí |
| `~/.dev-env/config/` | Lokální přepsání profilu |
| `~/.gitconfig.user` | Osobní Git identita |
| `~/.npmrc`, `~/.aws/`, `~/.azure/` | Tokeny a credentials |

---

*dev-env v1.1.0 · [manifest.json](manifest.json)*
