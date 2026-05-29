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
# Windows (PowerShell 7+)
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex
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
  git clone ... → C:\Users\...\.dev-env\repo
  Repo: C:\Users\...\.dev-env\repo

>>> PROFILE: home (auto-detected)
  Identity : jan@novak.cz
  Proxy    : none
  Package  : winget

Use: scripts/setup-home.ps1 -WhatIf
```

---

## 🔄 Co se stane

```
irm | iex  →  detect  →  report  →  clone  →  profile  →  setup  →  repair  →  test
                                                                              ↓
                                                                         menu.ps1
```

| Krok | Skript | Stav | Popis |
|---|---|---|---|
| **1. Detect** | `bootstrap.ps1` (gist) | ✅ | Fingerprint, OS, nástroje, PATH, OneDrive, firemní signály |
| **2. Report** | → `~/.dev-env/report-*.json` | ✅ | JSON pro AI i člověka |
| **3. Clone** | → `~/.dev-env/repo/` | ✅ | `git clone` repa (vyžaduje git) |
| **4. Profile** | `scripts/profile.ps1` | ✅ | home / work / lab — auto-detekce |
| **5. Setup** | `scripts/setup-home.ps1` | ✅ home | Winget, složky, git, symlinky |
| **6. Repair** | `scripts/repair.ps1` | ✅ | PATH, HOME, OneDrive, SSH |
| **7. Test** | `scripts/test.ps1` | ✅ | 14 kontrol — exit 0 = pass |
| **8. Menu** | `menu/menu.ps1` | ✅ | Interaktivní rozcestník |

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
       │   ├── profile.ps1       ← cd ~/.dev-env/repo && ./scripts/profile.ps1
       │   ├── setup-home.ps1
       │   ├── repair.ps1
       │   ├── test.ps1
       │   └── link-configs.ps1
       ├── menu/menu.ps1
       ├── ai/ docs/ profiles/
       └── ...
```

---

## 🧪 První kroky po instalaci

```powershell
# 1. Spusť bootstrap (pokud už neběží)
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex

# 2. Přejdi do naklonovaného repa
cd ~/.dev-env/repo

# 3. Zkontroluj profil
./scripts/profile.ps1

# 4. Suchý běh instalace — uvidíš, co se nainstaluje
./scripts/setup-home.ps1 -WhatIf

# 5. Instaluj (až budeš připraven)
./scripts/setup-home.ps1 -Force

# 6. Oprav problémy
./scripts/repair.ps1 -WhatIf
./scripts/repair.ps1 -Force

# 7. Otestuj
./scripts/test.ps1

# 8. Otevři menu
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
| `scripts/*.ps1` | 🔧 Spustit | Setup, repair, test, link, profile |
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
| ✅ | Bootstrap — detect, fingerprint, report, clone |
| ✅ | Profily — base, home, work, lab + auto-detekce |
| ✅ | Setup-home — winget, složky, git, symlinky |
| ✅ | Repair — PATH, HOME, OneDrive, SSH |
| ✅ | Test — 14 kontrol |
| ✅ | Menu — interaktivní rozcestník |
| ✅ | AI context — lifecycle, prompty, OS logika |
| ✅ | Landing — index.html (offline) + docs/index.md (Pages) |
| ✅ | Manifest — autoritativní metadata |
| 🟠 | `scripts/setup-work.ps1` — firemní instalace (proxy, VPN) |
| 🟠 | `scripts/setup-lab.ps1` — testovací VM (WSL, scoop) |
| 🟠 | Deep merge v `profile.ps1` — zatím shallow merge |
| 🟠 | Git config autocrlf → input (aplikovat lokálně) |

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
