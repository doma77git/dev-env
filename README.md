# 🧰 dev-env

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

# Windows — dry-run (detekce + profil + setup náhled, nic se neinstaluje)
$env:DEV_ENV_WHATIF='1'; irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex
```

```bash
# Linux / WSL (bash)
curl -fsSL https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.sh | bash
```

### Co uvidíš

```
>>> DETECT / DETEKCE

╔══════════════════════════════════════════╗
║  🔴  NEW                                 ║
║                                          ║
║  REPO : https://github.com/doma77git/... ║
║  RPT  : C:\Users\...\.dev-env\report-... ║
╚══════════════════════════════════════════╝

>>> CLONE / KLONUJI REPO
  git clone -b master ... → C:\Users\...\.dev-env\repo
  Repo: C:\Users\...\.dev-env\repo

>>> PROFILE: home (auto-detected)
  Reason   : no domain, no proxy, no VM

  ── SYSTEM ──────────────────────────────────
  OS       : Microsoft Windows 11 Pro (build 26200)
  Hostname : H11
  Domain   : WORKGROUP (workgroup)
  Profile  : 🏠 HOME — personal PC
  ── USER ────────────────────────────────────
  Account  : H11\spravce
  Type     : Local account
  ── IDENTITIES ──────────────────────────────
  Git      : doma77 <doma77@outlook.cz> (git-config)
  GitHub   : doma77git (logged in)
  SSH keys : 1 (ed25519)
  ── TOOLS ───────────────────────────────────
  Proxy    : none
  Package  : winget

  Use / Pouzij:  scripts/50-setup-home.ps1 -WhatIf
```

---

## 🔄 Co se stane

```
irm | iex
  ├─ PS7? ──ano──▶ PHASE 00 → 10 → 20 → 30 → 40 → 50 setup dry-run
  └─ PS5? ──────▶ 00-bootstrap-fallback.ps1 → nainstaluje pwsh+wt+git
                     └─▶ pwsh → hlavní pipeline
```

| Fáze | Skript | Stav | Popis |
|---|---|---|---|
| **00. Bootstrap** | `bootstrap.ps1` (gist) | ✅ | Entry point, gist URL, hand-off do fáze 10 |
| **10. Detect** | `bootstrap.ps1` inline | ✅ | Fingerprint, OS, nástroje, PATH, OneDrive, firemní signály |
| **20. Report** | → `~/.dev-env/report-*.json` | ✅ | JSON pro AI i člověka |
| **30. Clone** | → `~/.dev-env/repo/` | ✅ | `git clone` repa (vyžaduje git) |
| **40. Profile** | `scripts/40-profile.ps1` | ✅ | home / work / lab — auto-detekce |
| **50. Setup** | `scripts/50-setup-home.ps1` | ✅ home | Winget, složky, git, symlinky |
| **60. Repair** | `scripts/60-repair.ps1` | ✅ | PATH, HOME, OneDrive, SSH |
| **70. Test** | `scripts/70-test.ps1` | ✅ | 14 kontrol — exit 0 = pass |
| **Menu** | `menu/menu.ps1` | ✅ | Interaktivní rozcestník |

---

## ⚠️ DŮLEŽITÉ — varování

| Varování | Vysvětlení |
|---|---|
| 🔒 **Nikdy necommituj `~/.ssh/`** | SSH klíče = tvé digitální otisky. Únik = kompromitace všech serverů. |
| 🔒 **Nikdy necommituj `machines.json`** | Obsahuje hostname, username, doménu, cesty — recon sen pro útočníka. Je to lokální historie. |
| 🟡 **Bez gitu = bez clone** | Bootstrap detekci zvládne bez gitu. Ale repo se neklonuje → `scripts/` nebudou dostupné. Nainstaluj git a spusť bootstrap znovu. |
| 🟡 **PowerShell 7+, ne 5.1** | `profile.ps1` používá `??` operátor (PS 7+). Windows 10/11 mají PowerShell 5.1. Nainstaluj `winget install Microsoft.PowerShell`. |
| 🟡 **Firemní stroj = omezení** | GPO může blokovat `irm`, `iex`, `winget`. Bootstrap to detekuje — použij `work` profil. |
| 🔵 **OneDrive přesměrování** | Bootstrap detekuje, `repair.ps1` varuje. Desktop v OneDrive = každý screenshot se syncuje do cloudu. |

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
       ├── scripts/
       │   ├── 00-bootstrap-fallback.ps1  ← PS5 fallback
       │   ├── 40-profile.ps1
       │   ├── 50-setup-home.ps1
       │   ├── 50-setup-lab.ps1
       │   ├── 50-setup-work.ps1
       │   ├── 60-repair.ps1
       │   ├── 70-test.ps1
       │   └── link-configs.ps1
       ├── menu/menu.ps1
       ├── ai/ docs/ profiles/
       └── ...
```

---

## 🧪 První kroky po instalaci

```powershell
# 1. Dry-run — detekce + profil + setup náhled (nic se neinstaluje)
$env:DEV_ENV_WHATIF='1'
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex

# 2. Ostrý run — detekce + pull + profil (uloží se)
Remove-Item Env:\DEV_ENV_WHATIF -ErrorAction SilentlyContinue
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex

# 3. Přejdi do naklonovaného repa
cd ~/.dev-env/repo

# 4. Zkontroluj profil
./scripts/40-profile.ps1

# 5. Suchý běh instalace — uvidíš, co se nainstaluje
./scripts/50-setup-home.ps1 -WhatIf

# 6. Instaluj (až budeš připraven)
./scripts/50-setup-home.ps1 -Force

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
| `bootstrap.ps1` / `.sh` | 🔧 Spustit | Entry point — detect + clone + profile |
| `manifest.json` | ⚙️ Stroj | Autoritativní data: verze, timestamp, seznam souborů |
| `ai/context.md` | 🤖 AI | Kompletní kontext: lifecycle, rozhodování, prompty, OS logika |
| `ai/schema.json` | 🤖 AI | JSON Schema reportu |
| `docs/index.md` | 👤 Člověk | Landing page (GitHub Pages) |
| `docs/architecture.md` | 👤 Člověk | Jak to funguje |
| `docs/workflows.md` | 👤 Člověk | Krok za krokem |
| `index.html` | 👤 Offline | Lokální landing (otevři v prohlížeči) |
| `profiles/*.json` | ⚙️ Stroj | Definice home / work / lab |
| `scripts/00-bootstrap-fallback.ps1` | 🔧 Spustit | PS5 fallback — nainstaluje pwsh+wt+git |
| `scripts/40-profile.ps1`  | 🔧 Spustit | Detekce profilu home/work/lab |
| `scripts/50-setup-home.ps1` | 🔧 Spustit | Home PC — winget, dirs, git, autocrlf |
| `scripts/50-setup-work.ps1` | 🔧 Spustit | Corporate PC — proxy, VPN, manual |
| `scripts/50-setup-lab.ps1`  | 🔧 Spustit | Lab VM — WSL, scoop, experimental |
| `scripts/60-repair.ps1`     | 🔧 Spustit | Opravy PATH, HOME, OneDrive, SSH |
| `scripts/70-test.ps1`       | 🔧 Spustit | 14 kontrol, exit 0 = pass |
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
| ✅ | Bootstrap — detect, fingerprint, report, clone, WhatIf chain |
| ✅ | Profily — base, home, work, lab + auto-detekce s reasoning |
| ✅ | Profil výstup — 3 sekce: SYSTEM / USER / IDENTITIES |
| ✅ | Identita — auto-detekce z git configu (ne placeholder) |
| ✅ | GitHub + SSH detekce v profilu |
| ✅ | Phase numbering 00–70 (step 10) — prostor pro sub-fáze |
| ✅ | `scripts/00-bootstrap-fallback.ps1` — PS5 fallback (check→recommend→try→run) |
| ✅ | `scripts/50-setup-home.ps1` — winget, složky, git, symlinky |
| ✅ | `scripts/50-setup-work.ps1` — firemní instalace (proxy, VPN, manual) |
| ✅ | `scripts/50-setup-lab.ps1` — testovací VM (WSL, scoop) |
| ✅ | `scripts/60-repair.ps1` — PATH, HOME, OneDrive, SSH |
| ✅ | `scripts/70-test.ps1` — 14 kontrol |
| ✅ | Menu — interaktivní rozcestník |
| ✅ | AI context — lifecycle, prompty, OS logika |
| ✅ | Deep merge v `profile.ps1` — rekurzivní merge |
| ✅ | Git branch `master` — fixnuto clone/pull/tracking |
| ✅ | Porovnávač tools — robustní, žádné falešné "Gone" |
| 🟠 | **Setup podle `tools.required/recommended/optional`** — neinstalovat všechno |
| 🟠 | Linux/WSL `bootstrap.sh` — parity s `.ps1` verzí |
| 🟠 | `setup-home.ps1` config — identity, packages výběr, interaktivní režim |

---

## ⚠️ Co se nikdy nesyncuje

| Složka | Důvod |
|---|---|
| `~/.ssh/` | SSH klíče — digitální otisky |
| `~/.dev-env/machines.json` | Lokální historie detekcí |
| `~/.dev-env/config/` | Lokální přepsání profilu |
| `~/.gitconfig.user` | Osobní Git identita |
| `~/.npmrc`, `~/.aws/`, `~/.azure/` | Tokeny a credentials |

---

*dev-env v1.0.0 · [manifest.json](manifest.json)*
