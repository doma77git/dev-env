# 🧰 dev-env

> One command. Full inventory. All machines.  
> Jeden příkaz. Plná inventura. Všechny stroje.

---

## ⚠️ Než začneš

- **PowerShell 7+** — `bootstrap.ps1` vyžaduje PS7. Na PS5 spusť `00-bootstrap-fallback.ps1` (detekuje→doporučí→exit).
- **-WhatIf před -Force** — všechny skripty podporují suchý běh. Vždycky nejdřív `-WhatIf` nebo `-Confirm`.
- **Firemní stroj** — `safeMode` se automaticky detekuje. Nikdy nic neinstaluje bez potvrzení.
- **Server / headless** — detekuje se podle OS caption. safeMode = true.

---

## ⚡ Quickstart / Rychlý start

```powershell
# Windows PS7 — doporučeno
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex

# Windows PS5 — fallback (detekuje, doporučí, neinstaluje)
powershell -NoProfile -Command "irm https://gist.githubusercontent.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/00-bootstrap-fallback.ps1?v=1 | iex"
```

```bash
# Linux / WSL
curl -fsSL https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.sh | bash
```

---

## 🔄 Jak to funguje

```
irm | iex
  ├─ PS7 ──▶ 00→30→10→20→40→50→60→70
  └─ PS5 ──▶ 00-bootstrap-fallback → detect→recommend→exit
```

| Fáze | Skript | Co se děje |
|---|---|---|
| **00. Core check** | `00-core-check.ps1` | PS7, git, connectivity — exit 1 při chybě (neinstaluje) |
| **30. Clone** | `30-clone.ps1` | git clone/pull — vždy běží i v dry-run (read-only) |
| **10. Detect** | `10-detect.ps1` | Fingerprint, OS, 18 tools, PATH, OneDrive, corporate |
| **20. Report** | `20-report.ps1` | JSON → `~/.dev-env/report-*.json` + `machines.json` |
| **40. Profile** | `40-profile.ps1` | home/work/lab/server identity, git, GitHub, SSH |
| **50. Setup** | `50-setup-{profile}.ps1` | Balíčky, složky, git config (ShouldProcess) |
| **60. Repair** | `60-repair.ps1` | PATH, HOME, OneDrive, SSH (ShouldProcess) |
| **70. Test** | `70-test.ps1` | 17 kontrol — exit 0 = pass |

---

## 👤 Profily

| Profil | Spouští se když | safeMode |
|---|---|---|
| 🏠 **home** | WORKGROUP, žádný proxy, ne VM | ❌ |
| 🏢 **work** | Doména (≠ WORKGROUP), proxy | ✅ |
| 🧪 **lab** | VMware/VirtualBox / Virtuální model | ❌ |
| 🖳 **server** | OS caption "Server" | ✅ |

---

## 📂 Adresářová struktura

```
~/.dev-env/
├── machines.json           ← historie detekcí (nikdy nesyncovat)
├── report-*.json           ← poslední report
├── config/                 ← lokální přepsání profilu
└── repo/                   ← git clone repozitáře
    ├── bootstrap.ps1       ← orchestrátor
    ├── scripts/
    │   ├── 00-core-check.ps1        ← PS7, git, connectivity
    │   ├── 00-bootstrap-fallback.ps1← PS5 fallback
    │   ├── 10-detect.ps1            ← inventura
    │   ├── 20-report.ps1            ← report + JSON
    │   ├── 30-clone.ps1             ← clone/pull
    │   ├── 40-profile.ps1           ← profil
    │   ├── 50-setup-home.ps1        ← home instalace
    │   ├── 50-setup-lab.ps1         ← VM
    │   ├── 50-setup-work.ps1        ← firemní
    │   ├── 50-setup-server.ps1      ← server (headless)
    │   ├── 60-repair.ps1            ← opravy (ShouldProcess)
    │   ├── 70-test.ps1              ← validace (17 checks)
    │   ├── Confirm-Action.ps1       ← potvrzovací dialog (10s)
    │   ├── link-configs.ps1         ← symlinky
    │   └── undo-last.ps1            ← rollback guidance
    ├── profiles/             ← JSON definice profilů
    ├── configs/              ← verzované konfigy
    ├── ai/                   ← pro AI agenty
    └── docs/                 ← dokumentace
```

```
Doporučená struktura projektů:
~/dev/projects/
├── osobni/                 ← osobní projekty
├── ppg/                    ← firemní projekty
└── lab/                    ← experimenty
```

---

## 🧪 Skripty

| Skript | Spuštění | Co dělá |
|---|---|---|
| `scripts/00-core-check.ps1` | `./00-core-check.ps1` | Detekce PS7, git, connectivity |
| `scripts/10-detect.ps1` | `./10-detect.ps1` | Inventura prostředí |
| `scripts/20-report.ps1` | `./20-report.ps1` | Zobrazení + JSON |
| `scripts/30-clone.ps1` | `./30-clone.ps1` | Git clone/pull |
| `scripts/40-profile.ps1` | `./40-profile.ps1` | Detekce profilu |
| `scripts/50-setup-home.ps1` | `./50-setup-home.ps1 -WhatIf` | Instalace (ShouldProcess) |
| `scripts/60-repair.ps1` | `./60-repair.ps1 -WhatIf` | Opravy (ShouldProcess) |
| `scripts/70-test.ps1` | `./70-test.ps1` | 17 kontrol |
| `scripts/link-configs.ps1` | `./link-configs.ps1 -WhatIf` | Symlinky konfigů |
| `scripts/Confirm-Action.ps1` | dot-source | Interaktivní potvrzení (10s timeout) |
| `scripts/undo-last.ps1` | `./undo-last.ps1` | Rollback — zobrazí poslední log |
| `menu/menu.ps1` | `./menu.ps1` | Interaktivní menu |

---

## 🗺️ Odkazy

| Kam | URL |
|---|---|
| 🔩 Repo | [github.com/doma77git/dev-env](https://github.com/doma77git/dev-env) |
| ⚡ Gist | `https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5` |
| 🧠 Manifest | [manifest.json](../manifest.json) |
| 📐 Schema | [ai/schema.json](../ai/schema.json) |
| 🏗️ Architektura | [docs/architecture.md](architecture.md) |
| 🔄 Workflow | [docs/workflows.md](workflows.md) |

---

## ⚠️ Co se nikdy nesyncuje

> Kanonický seznam: [`profiles/base.json#/secrets`](../profiles/base.json) — jediný zdroj pravdy.

| Složka | Důvod |
|---|---|
| `~/.ssh/` | SSH klíče |
| `~/.dev-env/machines.json` | Lokální historie |
| `~/.dev-env/config/` | Lokální přepsání |
| `~/.gitconfig.user` | Osobní identita |
| `~/.npmrc`, `~/.aws/`, `~/.azure/` | Tokeny |

---

## 🧠 Pro AI agenty

- **Manifest**: [`manifest.json`](../manifest.json) — autoritativní popis celého projektu
- **Schema**: [`ai/schema.json`](../ai/schema.json) — struktura reportu
- **Profily**: [`profiles/*.json`](../profiles/) — definice prostředí

---

*dev-env v1.1.1 · 2026-05-31 · [manifest.json](../manifest.json)*
