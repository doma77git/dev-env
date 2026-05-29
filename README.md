# 🧰 dev-env

> One command. Full inventory. All machines.

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
| 🔧 **Chci rovnou spustit** | Čti níže ↓ |

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

## 📂 Soubory — k čemu jsou

| Soubor | Pro koho | Účel |
|---|---|---|
| `bootstrap.ps1` / `.sh` | 🔧 Uživatel | Entry point — detect + clone + profile |
| `manifest.json` | ⚙️ Stroj | Autoritativní data: verze, timestamp, seznam souborů, flow |
| `ai/context.md` | 🤖 AI | Kompletní kontext: lifecycle, rozhodování, prompty, OS logika |
| `ai/schema.json` | 🤖 AI | JSON Schema reportu |
| `docs/index.md` | 👤 Člověk | Landing page (GitHub Pages) |
| `docs/architecture.md` | 👤 Člověk | Jak to funguje pod kapotou |
| `docs/workflows.md` | 👤 Člověk | Krok-za-krokem postupy |
| `profiles/*.json` | ⚙️ Stroj | Definice profilů (home/work/lab) |
| `scripts/*.ps1` | 🔧 Uživatel | Setup, repair, test, link, profile |
| `configs/*` | 🔧 Uživatel | Sdílené konfigy (git, pwsh) |
| `menu/menu.ps1` | 🔧 Uživatel | Interaktivní menu |

---

## 🗺️ Odkazy

| Kam | URL |
|---|---|
| Repo | [github.com/doma77git/dev-env](https://github.com/doma77git/dev-env) |
| Pages | [doma77git.github.io/dev-env](https://doma77git.github.io/dev-env) |

---

## 🤖 Pro AI: tvůj první prompt

> Přečti [`ai/context.md`](ai/context.md) — všechno ostatní z něj plyne.

---

## 👤 Pro člověka: co se ptát

| Chceš... | Zeptej se / spusť |
|---|---|
| Zjistit stav stroje | `irm <gist> \| iex` |
| Opravit prostředí | `./scripts/repair.ps1 -WhatIf` |
| Nainstalovat nástroje | `./scripts/setup-home.ps1 -WhatIf` |
| Ověřit, že vše funguje | `./scripts/test.ps1` |
| Otevřít menu | `./menu/menu.ps1` |
| Pochopit projekt | [`docs/architecture.md`](docs/architecture.md) |
| Poslat report AI | Zkopíruj JSON z `~/.dev-env/report-*.json` |
