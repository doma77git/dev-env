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
# Windows
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex
```

```bash
# Linux / WSL
curl -fsSL https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.sh | bash
```

---

## 🔄 Co se stane

```
irm | iex  →  detect  →  report  →  clone  →  profile  →  setup  →  repair  →  test
                                                                              ↓
                                                                         menu.ps1
```

| Krok | Skript | Stav |
|---|---|---|
| **1. Detect** | `bootstrap.ps1` (gist) | ✅ |
| **2. Report** | → `~/.dev-env/report-*.json` | ✅ |
| **3. Clone** | → `~/.dev-env/repo/` | ✅ |
| **4. Profile** | `scripts/profile.ps1` | ✅ home/work/lab |
| **5. Setup** | `scripts/setup-home.ps1` | ✅ home / 🟠 work+lab TODO |
| **6. Repair** | `scripts/repair.ps1` | ✅ |
| **7. Test** | `scripts/test.ps1` | ✅ |
| **8. Menu** | `menu/menu.ps1` | ✅ |

---

## 📂 Soubory — k čemu jsou

| Soubor | Pro koho | Účel |
|---|---|---|
| `bootstrap.ps1` / `.sh` | 🔧 Spustit | Entry point — detect + clone + profile |
| `manifest.json` | ⚙️ Stroj | Autoritativní data: verze, timestamp, seznam souborů |
| `ai/context.md` | 🤖 AI | Kompletní kontext: lifecycle, rozhodování, prompty |
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

## ⚠️ Co se nikdy nesyncuje

| Složka | Důvod |
|---|---|
| `~/.ssh/` | SSH klíče |
| `~/.dev-env/machines.json` | Lokální historie detekcí |
| `~/.dev-env/config/` | Lokální přepsání profilu |
| `~/.gitconfig.user` | Osobní Git identita |
| `~/.npmrc`, `~/.aws/`, `~/.azure/` | Tokeny |

---

*dev-env v1.0.0 · [manifest.json](manifest.json)*
