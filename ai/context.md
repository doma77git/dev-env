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
  irm <gist>/bootstrap.ps1 | iex          (Windows — ostrý run)
  $env:DEV_ENV_WHATIF='1'; irm ... | iex   (Windows — dry-run)
  ./bootstrap.ps1 -WhatIf                  (Windows — local dry-run)
  curl -fsSL <gist>/bootstrap.sh | bash   (Linux/WSL)

WHAT HAPPENS:
  bootstrap.*
    → 1. DETECT (self-contained, no dependencies)
    → 2. REPORT (JSON → stdout + ~/.dev-env/)
    → 3. CLONE (git clone -b master → ~/.dev-env/repo/)
    → 4. PROFILE (scripts/profile.ps1 → home|work|lab)
         → 3-sekční výstup: SYSTEM / USER / IDENTITIES
         → Identita: saved > git-config > placeholder
    → 5. SETUP DRY-RUN (když -WhatIf: auto-chain do setup-<profile>.ps1 -WhatIf)

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
USER runs: irm <gist> | iex  (nebo s $env:DEV_ENV_WHATIF='1')
  │
  ├─ $env:DEV_ENV_WHATIF='1'?
  │   → >>> DRY-RUN MODE
  │   → detect proběhne normálně (report se uloží)
  │   → profile běží s -WhatIf (neukládá se)
  │   → auto-chain: setup-<profile>.ps1 -WhatIf
  │
  ├─ ~/.dev-env/ DOESN'T EXIST?
  │   → status: 🔴 new
  │   → full detect
  │   → clone repo (git clone -b master)
  │   → detect profile
  │
  ├─ ~/.dev-env/ EXISTS?
  │   ├─ fingerprint MATCH?
  │   │   ├─ build CHANGED?   → 🟠 os-changed (reinstall/upgrade)
  │   │   ├─ tools CHANGED?   → 🟡 tools-changed (robustní porovnávač)
  │   │   └─ NOTHING CHANGED? → 🟢 same
  │   │
  │   └─ fingerprint NO MATCH?
  │       → 🔴 new (different machine/user)
  │
  ├─ CLONE — repo handling:
  │   ├─ repo/ + .git existuje → git fetch + checkout master + pull
  │   ├─ repo/ bez .git        → Broken repo — smaže a git clone -b master
  │   └─ repo/ neexistuje      → git clone -b master
  │
  └─ PROFILE (scripts/profile.ps1):
      ├─ domain-joined ≠ WORKGROUP          → 🏢 work
      ├─ manufacturer = VMware|VirtualBox   → 🧪 lab
      ├─ proxy present, no domain           → 🏢 work (VPN?)
      └─ otherwise                          → 🏠 home
      └─ user override: -Set home|work|lab
      └─ IDENTITY: saved (identity.json) > git-config > profile placeholder
```

---

## COMMANDS / PŘÍKAZY — co říct uživateli

### When user says: "I have a new PC" / "Mám nový počítač"
```
# 1. Dry-run first — vždy!
$env:DEV_ENV_WHATIF='1'
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex

# 2. Ostrý run
Remove-Item Env:\DEV_ENV_WHATIF -ErrorAction SilentlyContinue
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex

# 3. Setup
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

1. **Never suggest committing** `~/.ssh/`, `~/.dev-env/config/`, `machines.json`, `identity.json` — these are local secrets
2. **Always suggest -WhatIf / dry-run first** — `$env:DEV_ENV_WHATIF='1'` before `irm | iex`
3. **Detect before suggesting** — ask user to run bootstrap first if no report available
4. **Profile matters** — home vs work have different package managers and restrictions
5. **Git is optional for detect** — bootstrap works without it; suggest install for full features
6. **Exit code** from test.ps1: 0 = all pass, 1 = some fail — use this for CI
7. **machines.json grows forever** — append-only; suggest truncation after 100+ entries
8. **Identita není placeholder** — profile.ps1 auto-detekuje z git configu; `setup-home.ps1 -Force` uloží do `identity.json`
9. **3-sekční profil** — SYSTEM (OS/domain/profile), USER (account/type), IDENTITIES (git/github/ssh)

---

## TODO / ROADMAP

| Status | Item |
|---|---|
| 🟠 | **Setup podle `tools.required/recommended/optional`** — neinstalovat všechno, respektovat profil |
| 🟠 | Linux/WSL `bootstrap.sh` — parity s `.ps1` verzí (WhatIf, identity detection, porovnávač) |
| 🟠 | `setup-home.ps1` — interaktivní režim (výběr packages, identity prompt) |
| 🟠 | SSH keygen prompt v setupu (když chybí klíče) |
| 🟠 | `menu/menu.ps1` — aktualizace na nové scripty |

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

---

## PROMPT TUNING / LADĚNÍ PROMPTŮ

### For AI: "User sent me a report — what do I say?"

```
You are a dev-env assistant. User just ran bootstrap and sent you this JSON report.

{ paste report here }

Do THIS in order:
1. STATUS FIRST — read `status` field. Is it "new", "same", "os-changed", or "tools-changed"?
2. QUICK SUMMARY — one sentence. Example: "🔴 Nový stroj H11 (Windows 11, build 26200, WORKGROUP). Git, Node, Python, VS Code nalezeny."
3. ISSUES — check `path.errors` array. List each error in plain language.
4. NEXT STEP — based on status, tell user exactly one command to run:
   - "new" → "Spusť: cd ~/.dev-env/repo && ./scripts/setup-home.ps1 -WhatIf"
   - "same" → "Vše v pořádku. Můžeš spustit: ./menu/menu.ps1"
   - "os-changed" → "Reinstal detekován. Spusť: ./scripts/setup-home.ps1 -Force"
   - "tools-changed" → "Nová verze nástrojů. Spusť: ./scripts/test.ps1"

RULES:
- Always CZ+EN bilingual in code references
- Never suggest committing secrets
- Always mention -WhatIf before -Force
- If `corporate.domainJoined: true` → mention work profile
- If `onedrive.redirects.Desktop` exists → warn about OneDrive sync
- If `tools.git: null` → first step is installing git
```

### For AI: "User asks 'what's wrong with my environment?'"

```
Read the report and `scripts/test.ps1` output. Categorize issues:

🔴 CRITICAL (fix immediately):
  - HOME not set → security risk, some tools break
  - PATH duplicates > 3 → potential conflicts
  - No SSH keys → can't connect to GitHub

🟡 WARNING (fix soon):
  - OneDrive redirects Desktop → privacy leak
  - PATH count > 50 → slows down shell startup
  - Missing recommended tools (docker, nvim)

🔵 INFO:
  - New tools detected (auto-updated)
  - OS build changed (Windows Update)

For each issue, suggest the EXACT repair command:
  scripts/repair.ps1 -WhatIf  (preview)
  scripts/repair.ps1 -Force   (apply)
```

### For AI: "User asks 'help me set up a new PC'"

```
🚨 WARNING — READ BEFORE RESPONDING:
- NEVER suggest installing things without -WhatIf first
- NEVER suggest `rm -rf` or `Remove-Item -Recurse -Force` on home dirs
- ALWAYS check if the user is on a corporate machine (proxy, GPO, VPN)
- ALWAYS explain what each command does BEFORE suggesting it

Response template:
1. "First, run bootstrap to detect your environment: irm <gist> | iex"
2. "Send me the JSON output or paste it here."
3. [After receiving report] "Your profile is {home|work|lab}. Here's your setup plan:"
4. List commands with explanations
5. "Start with: cd ~/.dev-env/repo && ./scripts/setup-{profile}.ps1 -WhatIf"
```

---

## WARNINGS FOR AI / VAROVÁNÍ PRO AI

| # | Rule | Why |
|---|---|---|
| 1 | **Never suggest `git push` of config/ or .ssh/** | Contains local secrets |
| 2 | **Never suggest `Remove-Item -Recurse ~/`** | Destructive — could wipe user data |
| 3 | **Always suggest -WhatIf before -Force** | User must see what will change |
| 4 | **Never hardcode paths** | Use `$env:USERPROFILE`, `$HOME`, `~` |
| 5 | **Corporate machine = different rules** | No winget, proxy required, VPN may be needed |
| 6 | **`machines.json` is append-only** | Don't suggest editing it — suggest deleting if corrupt |
| 7 | **Report JSON is the source of truth** | Always read it before suggesting actions |
| 8 | **PowerShell 7+ required** | `profile.ps1` uses `??` operator — won't work on PS 5.1 |

---

## ADVANCED SCENARIOS / POKROČILÉ SCÉNÁŘE

### Multi-machine sync
```
User has 3 machines (home PC, PPG laptop, lab VM).
All use the same gist. Each has its own machines.json.

How to keep in sync:
1. Bootstrap runs on each machine separately
2. Each machine has its own fingerprint → separate entries in its own machines.json
3. Repo changes (scripts, profiles) sync via git pull
4. Profile auto-detection ensures correct packages per machine
5. NEVER merge machines.json across machines — they're machine-specific
```

### Corporate machine without admin
```
Bootstrap detects: domainJoined=true, proxy present, no winget
→ Profile: work
→ setup-work.ps1 (TODO) will handle:
  - Manual installation instructions (no winget)
  - Proxy configuration for git, npm, pip
  - ExecutionPolicy workarounds
  - Portable app suggestions
```

### After OS reinstall
```
Bootstrap detects: fingerprint same, build changed, installDate new
→ Status: os-changed
→ User should run:
  1. setup-home.ps1 -Force (reinstall all packages)
  2. repair.ps1 -Force (fix PATH, HOME)
  3. link-configs.ps1 -Force (restore config symlinks)
  4. test.ps1 (verify everything)
```
