# 🤖 AI CONTEXT — dev-env

> **Read this first.** Everything you need to understand and operate this project.
> Valid for: GPT, Claude, Reasonix, local models. OS-independent.

---

## WHAT IS THIS / O CO JDE

A **portable developer environment bootstrap system**.
One gist, one repo, all machines. Detects, reports, repairs, tests.

| Term | Means |
|---|---|
| `bootstrap` | Self-contained detect script — runs without git, without install |
| `fingerprint` | SHA256(hostname\|username\|domain) — unique machine+user ID |
| `profile` | `home` / `work` / `lab` — auto-detected machine context |
| `machines.json` | Append-only history — LOCAL, never synced, never committed |
| `WhatIf` | PowerShell dry-run convention — show what WOULD change |

---

## ARCHITECTURE / ARCHITEKTURA

```
USER runs:
  irm <gist>/bootstrap.ps1 | iex          (Windows)
  curl -fsSL <gist>/bootstrap.sh | bash   (Linux/WSL)

WHAT HAPPENS:
  bootstrap.*
    → 1. DETECT (self-contained, no dependencies)
    → 2. REPORT (JSON → stdout + ~/.dev-env/)
    → 3. CLONE (git clone repo → ~/.dev-env/repo/)
    → 4. PROFILE (scripts/profile.ps1 → home|work|lab)

  AFTER CLONE — user can run:
    → scripts/setup-<profile>.ps1 [-WhatIf|-Force]
    → scripts/repair.ps1          [-WhatIf|-Force]
    → scripts/test.ps1            (exit 0=pass, 1=fail)
    → scripts/link-configs.ps1    [-WhatIf|-Force]
    → menu/menu.ps1               (interactive)
```

---

## DECISION TREE / ROZHODOVACÍ STROM

```
USER runs: irm <gist> | iex
  │
  ├─ ~/.dev-env/ DOESN'T EXIST?
  │   → status: 🔴 new
  │   → full detect
  │   → clone repo
  │   → detect profile
  │
  ├─ ~/.dev-env/ EXISTS?
  │   ├─ fingerprint MATCH?
  │   │   ├─ build CHANGED?   → 🟠 os-changed (reinstall/upgrade)
  │   │   ├─ tools CHANGED?   → 🟡 tools-changed
  │   │   └─ NOTHING CHANGED? → 🟢 same
  │   │
  │   └─ fingerprint NO MATCH?
  │       → 🔴 new (different machine/user)
  │
  └─ PROFILE (scripts/profile.ps1):
      ├─ $env:USERDOMAIN ≠ "WORKGROUP"     → 🏢 work
      ├─ manufacturer = VMware|VirtualBox   → 🧪 lab
      ├─ proxy present, no domain           → 🏢 work (VPN?)
      └─ otherwise                          → 🏠 home
      └─ user override: -Set home|work|lab
```

---

## COMMANDS / PŘÍKAZY — co říct uživateli

### When user says: "I have a new PC" / "Mám nový počítač"
```
Run this in PowerShell:
  irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex
Then:
  cd ~/.dev-env/repo
  ./scripts/setup-home.ps1 -WhatIf    (review)
  ./scripts/setup-home.ps1 -Force     (apply)
  ./scripts/repair.ps1 -Force
  ./scripts/test.ps1
```

### When user says: "check my environment" / "zkontroluj prostředí"
```
  irm <gist> | iex
  cd ~/.dev-env/repo && ./scripts/test.ps1
```

### When user says: "something is broken" / "něco nefunguje"
```
  cd ~/.dev-env/repo
  ./scripts/repair.ps1 -WhatIf   (see what's wrong)
  ./scripts/repair.ps1 -Force    (fix it)
  ./scripts/test.ps1             (verify)
```

### When user says: "I reinstalled Windows" / "přeinstaloval jsem"
```
  irm <gist> | iex
  # Will show 🟠 os-changed
  cd ~/.dev-env/repo
  ./scripts/setup-home.ps1 -Force
  ./scripts/repair.ps1 -Force
  ./scripts/link-configs.ps1 -Force
  ./scripts/test.ps1
```

### When user says: "I'm at work" / "jsem v práci"
```
  irm <gist> | iex
  cd ~/.dev-env/repo
  ./scripts/profile.ps1 -Set work
  # Review restrictions — no winget, proxy required
  ./scripts/test.ps1
```

---

## HOW TO READ A REPORT / JAK ČÍST REPORT

Report JSON (from `~/.dev-env/report-*.json` or stdout):

```json
{
  "status": "new|same|os-changed|tools-changed",  ← KEY FIELD
  "fingerprint": "sha256...",
  "hostname": "...", "username": "...", "domain": "...",
  "os": { "caption": "Windows 11 Pro", "build": "26100", ... },
  "tools": { "git": "2.47.1 | C:\\...", "node": "v22.12.0 | C:\\...", ... },
  "path": { "count": 30, "errors": ["DUP: ...", "MISS: ..."] },
  "onedrive": { "accounts": {...}, "redirects": {"Desktop": "C:\\...\\OneDrive\\Desktop"} },
  "corporate": { "domainJoined": false, "proxy": null, ... },
  "changes": ["OS build: 22621 → 26100", "New: docker"]
}
```

### Quick analysis:
| Field | Red flag if |
|---|---|
| `status: "os-changed"` | Reinstall detected → suggest full setup |
| `path.errors: [...]` | PATH issues → suggest repair.ps1 |
| `onedrive.redirects.Desktop` | OneDrive redirect → suggest repair |
| `corporate.domainJoined: true` | Corporate machine → suggest work profile |
| `tools.git: null` | No git → can't clone repo, suggest install first |
| `os.build < 22000` | Windows 10 or older |

---

## LIFECYCLE / ŽIVOTNÍ CYKLUS

```
┌─────────────────────────────────────────────────────────┐
│                     LIFECYCLE                            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. BOOTSTRAP                                           │
│     User: irm <gist> | iex                              │
│     AI: "Here's what I found on your machine..."        │
│     → detect → report → clone → profile                 │
│                                                         │
│  2. SETUP                                               │
│     User: setup-<profile>.ps1 -Force                    │
│     AI: "I'll install these packages, create folders..."│
│     → winget/brew/apt → dirs → symlinks → git identity  │
│                                                         │
│  3. REPAIR                                              │
│     User: repair.ps1 -Force                             │
│     AI: "Fixing: HOME, PATH duplicates, OneDrive..."    │
│     → setx HOME → dedupe PATH → unlink OneDrive         │
│                                                         │
│  4. TEST                                                │
│     User: test.ps1                                      │
│     AI: "12/14 pass. Issues: HOME not set, OneDrive..." │
│     → ✅/❌ per check → exit code 0 or 1                │
│                                                         │
│  5. MAINTAIN                                            │
│     User: menu.ps1 or irm <gist> | iex                  │
│     AI: "Nothing changed 🟢" or "New: docker 🟡"        │
│     → periodic check → pull repo → re-test              │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## FILES MAP / MAPA SOUBORŮ — for AI navigation

```
WHEN USER SAYS:                     LOOK AT:
─────────────────────────────────────────────────────────
"What is this project?"          → manifest.json, README.md
"How does it work?"              → docs/architecture.md
"What do I do now?"              → docs/workflows.md, ai/context.md (this file)
"I need to understand the code"  → bootstrap.ps1 (detect), scripts/*.ps1
"What's the data format?"        → ai/schema.json
"Which profile am I?"            → profiles/home.json|work.json|lab.json
"Check my machine"               → ~/.dev-env/report-*.json
"History of this machine"        → ~/.dev-env/machines.json
```

---

## OS-INDEPENDENT LOGIC

| Concept | Windows | Linux/WSL |
|---|---|---|
| Home dir | `$env:USERPROFILE` | `$HOME` |
| Output dir | `~\\.dev-env\\` | `~/.dev-env/` |
| Path separator | `;` | `:` |
| Path issues check | `Test-Path` | `[ -d "$dir" ]` |
| Package manager | `winget` / `scoop` | `apt` / `brew` |
| OneDrive | check registry | N/A (skip) |
| Corporate check | `$env:USERDOMAIN`, `PartOfDomain` | `domainname`, `realm` |

---

## PROMPTS / PROMPTY — co použít

### For AI: "Analyze this report"
```
Here is a dev-env detection report. Analyze it:

{ paste JSON from ~/.dev-env/report-*.json }

Tell me:
1. What's the status? (new/same/changed)
2. What issues are there? (PATH errors, OneDrive, corporate)
3. What should I do next? (setup/repair/test)
4. What profile am I using?
```

### For AI: "Help me set up"
```
I'm on a [new|existing|reinstalled] machine.
Profile: [home|work|lab]
Report: { paste JSON if available }

Tell me the exact commands to run, in order.
```

### For AI: "Review my environment"
```
Here's my latest machines.json history.
What changed between the last 2 runs?
What should I fix?

{ paste ~/.dev-env/machines.json }
```

---

## RULES FOR AI AGENTS

1. **Never suggest committing** `~/.ssh/`, `~/.dev-env/config/`, `machines.json` — these are local secrets
2. **Always suggest -WhatIf first** — all setup/repair scripts support dry-run
3. **Detect before suggesting** — ask user to run bootstrap first if no report available
4. **Profile matters** — home vs work have different package managers and restrictions
5. **Git is optional for detect** — bootstrap works without it; suggest install for full features
6. **Exit code** from test.ps1: 0 = all pass, 1 = some fail — use this for CI
7. **machines.json grows forever** — append-only; suggest truncation after 100+ entries

---

## TODO / ROADMAP

| Status | Item |
|---|---|
| 🟠 | `scripts/setup-work.ps1` — corporate PC setup (proxy, VPN, restricted) |
| 🟠 | `scripts/setup-lab.ps1` — lab VM setup (WSL, scoop, experimental) |
| 🟠 | Deep merge in `profile.ps1` — nested keys from base not preserved |
| 🟠 | Git push blocked — email privacy. User must fix at github.com/settings/emails |

---

## SYNC / SYNCHRONIZACE

| What | Where | How | When |
|---|---|---|---|
| `bootstrap.ps1/.sh` | Gist | Manual copy from repo | When changed |
| Repo | GitHub | `git push/pull` | On demand |
| `~/.dev-env/repo/` | Local clone | `git pull` (bootstrap or menu) | On each run |
| `machines.json` | **Local only** | Never sync | — |
| `~/.dev-env/config/` | **Local only** | Never sync | — |
| `~/.ssh/` | **Local only** | Never sync | — |
| Configs (`~/.gitconfig`...) | Symlink from repo | `link-configs.ps1` | After setup |
