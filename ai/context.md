# 🤖 AI CONTEXT — dev-env

> **Read this first.** Everything you need to understand and operate this project.
> Valid for: GPT, Claude, Reasonix, CodeWhale, local models. OS-independent.

---

## WHAT IS THIS / O CO JDE

A **portable developer environment bootstrap system**.
One gist, one repo, all machines. Detects, reports, repairs, tests.

| Term | Means |
|---|---|
| `bootstrap` | Self-contained detect script — runs without git, without install |
| `fingerprint` | SHA256(hostname\|username\|domain) — unique machine+user ID |
| `profile` | `home` / `work` / `lab` / `server` — auto-detected machine context |
| `machines.json` | Append-only history — LOCAL, never synced, never committed |
| `WhatIf` | PowerShell dry-run convention — show what WOULD change |
| `ShouldProcess` | PowerShell advanced function — enables -WhatIf, -Confirm on mutations |
| `Transcript` | PowerShell logging — captures all phase 50-60 output to ~/.dev-env/logs/ |
| `GPG signing` | Git commit signing — detected and recommended for work/server profiles |

---

## ARCHITECTURE / ARCHITEKTURA

```
USER runs:
  irm <gist>/bootstrap.ps1 | iex          (Windows — ostrý run)
  $env:DEV_ENV_WHATIF='1'; irm ... | iex   (Windows — dry-run)
  ./bootstrap.ps1 -WhatIf                  (Windows — local dry-run)
  curl -fsSL <gist>/bootstrap.sh | bash   (Linux/WSL)
  DEV_ENV_WHATIF=1 curl ... | bash        (Linux/WSL — dry-run)

WHAT HAPPENS:
  bootstrap.*  → orchestrator volá fáze:
    → 00. CORE CHECK (scripts/00-core-check.ps1)
         PS7, git, connectivity → exit 1 při chybě (neinstaluje)
    → 30. CLONE (scripts/30-clone.ps1)
         git clone/pull → ~/.dev-env/repo/ (read-only, vždy běží)
    → 10. DETECT (scripts/10-detect.ps1)
         fingerprint, OS, 13 tools, PATH, OneDrive, corporate
    → 20. REPORT (scripts/20-report.ps1)
         JSON → stdout + ~/.dev-env/report-*.json + machines.json
    → 40. PROFILE (scripts/40-profile.ps1), GPG
    → 50. SETUP (scripts/50-setup-{profile}.ps1, ShouldProcess)
         dry-run + confirm → instalace (📝 transcript logged)
    → 60. REPAIR (scripts/60-repair.ps1, ShouldProcess)
         PATH, HOME, OneDrive, SSH (📝 transcript logged)
    → 70. TEST (scripts/70-test.ps1)
         15EST (scripts/70-test.ps1)
         14 checks → exit 0=pass, 1=fail
```

---

## DECISION TREE / ROZHODOVACÍ STROM

```
USER runs: irm <gist> | iex  (nebo s $env:DEV_ENV_WHATIF='1')
  │
  ├─ $env:DEV_ENV_WHATIF='1'?
  │   → >>> DRY-RUN MODE
  │   → clone proběhne (read-only)
  │   → detect/report uloží JSON
  │   → profile s -WhatIf (neukládá se)
  │   → setup/repair dry-run + confirm timeout → skip
  │
  ├─ Phase 00 — Core check:
  │   PS7+? → continue
  │   PS5?  → "Install manually" → exit 1
  │   git?  → continue
  │   no git → "Install manually" → exit 1
  │   ping github.com → OK/warning
  │
  ├─ Phase 30 — Clone:
  │   repo/.git exists → git pull → checkout HEAD -- scripts/
  │   broken repo      → Remove-Item scripts/ + checkout
  │   no repo          → git clone -b master
  │
  ├─ Phase 10 — Detect:
  │   fingerprint, OS, tools, PATH, OneDrive, corporate
  │   Compare with previous (machines.json):
  │   → new / same / os-changed / tools-changed
  │
  ├─ Phase 20 — Report:
  │   Display status → save JSON
  │
  ├─ Phase 40 — Profile:
  │   saved > domain > OS > manufacturer > proxy > home
  │   Git identity: saved > git-config > placeholder
  │
  ├─ Phase 50 — Setup (ShouldProcess):
  │   -WhatIf → dry-run
  │   no switch → dry-run + confirm 10s timeout
  │   -Force → apply all (CI/CD)
  │   -Confirm → ask per operation
  │
  ├─ Phase 60 — Repair (ShouldProcess):
  │   Same as 50: -WhatIf | confirm | -Force | -Confirm
  │
  └─ Phase 70 — Test:
      14 checks → pass/fail → exit code
```

---

## COMMANDS / PŘÍKAZY — co říct uživateli

### When user says: "I have a new PC" / "Mám nový počítač"
```
# 1. Dry-run first — vždy!
$env:DEV_ENV_WHATIF='1'
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex

# 2. Ostrý run
irm https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5/raw/bootstrap.ps1 | iex

# 3. Setup
cd ~/.dev-env/repo
./scripts/50-setup-home.ps1 -WhatIf    (review)
./scripts/50-setup-home.ps1 -Force     (apply)
./scripts/60-repair.ps1 -Force
./scripts/70-test.ps1
```

### When user says: "check my environment" / "zkontroluj prostředí"
```
  irm <gist> | iex
  cd ~/.dev-env/repo && ./scripts/70-test.ps1
```

### When user says: "something is broken" / "něco nefunguje"
```
  cd ~/.dev-env/repo
  ./scripts/60-repair.ps1 -WhatIf   (see what's wrong)
  ./scripts/60-repair.ps1 -Force    (fix it)
  ./scripts/70-test.ps1             (verify)
```

### When user says: "I reinstalled Windows" / "přeinstaloval jsem"
```
  irm <gist> | iex
  # Will show 🟠 os-changed
  cd ~/.dev-env/repo
  ./scripts/50-setup-home.ps1 -Force
  ./scripts/60-repair.ps1 -Force
  ./scripts/link-configs.ps1 -Force
  ./scripts/70-test.ps1
```

### When user says: "I'm at work" / "jsem v práci"
```
  irm <gist> | iex
  cd ~/.dev-env/repo
  ./scripts/40-profile.ps1 -Set work
  ./scripts/50-setup-work.ps1 -WhatIf
  ./scripts/70-test.ps1
```

---

## HOW TO READ A REPORT / JAK ČÍST REPORT

Report JSON (from `~/.dev-env/report-*.json` or stdout):

```json
{
  "status": "new|same|os-changed|tools-changed",
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
| `path.errors: [...]` | PATH issues → suggest repair |
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
│     → core check → clone → detect → report → profile    │
│                                                         │
│  2. SETUP                                               │
│     User: 50-setup-<profile>.ps1 -Force                 │
│     → winget → dirs → symlinks → git identity           │
│     → uses ShouldProcess (-WhatIf, -Confirm)             │
│                                                         │
│  3. REPAIR                                              │
│     User: 60-repair.ps1 -Force                          │
│     → PATH dedup → HOME → OneDrive → SSH                │
│                                                         │
│  4. TEST                                                │
│     User: 70-test.ps1                                   │
│     → 14 checks → ✅/❌ → exit code 0 or 1              │
│                                                         │
│  5. MAINTAIN                                            │
│     User: menu.ps1 or irm <gist> | iex                  │
│     → pull repo → re-test                               │
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
"I need to understand the code"  → bootstrap.ps1, scripts/*.ps1
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
6. **Exit code** from 70-test.ps1: 0 = all pass, 1 = some fail — use this for CI
7. **machines.json grows forever** — append-only; suggest truncation after 100+ entries
8. **Identita není placeholder** — 40-profile.ps1 auto-detekuje z git configu; `50-setup-home.ps1 -Force` uloží do `identity.json`
9. **3-sekční profil** — SYSTEM (OS/domain/profile), USER (account/type), IDENTITIES (git/github/ssh)
10. **Clone vždy běží** — i v dry-run režimu, je to read-only
11. **ShouldProcess** — setup/repair podporují -WhatIf, -Confirm, -Force
12. **PS5 fallback neinstaluje** — pouze detect→recommend→exit

---

## TODO / ROADMAP

| Status | Item |
|---|---|
| ✅ | Linux/WSL `bootstrap.sh` — parity s `.ps1` (v1.1.0: WhatIf, full pipeline 00→30→10→20→40→50) |
| ✅ | GPG commit signing — detekce a guidance pro work/server (v1.1.0) |
| ✅ | Rollback — transcript logging + `undo-last.ps1` (v1.1.0) |
| ✅ | CI/CD — GitHub Actions ci.yml + pr.yml + gist-sync.yml (v1.1.0) |
| ✅ | Server setup — `50-setup-server.ps1` (v1.1.0) |
| ✅ | Profile validation — JSON schema check v 40-profile.ps1 + 70-test.ps1 (v1.1.0) |
| 🟠 | Interaktivní režim v setup-home.ps1 (výběr packages) |
| 🟠 | SSH keygen prompt v setupu (když chybí klíče) |

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
| `~/.dev-env/logs/` | **Local only** | Never sync | Transcript logs |
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
   - "new" → "Spusť: cd ~/.dev-env/repo && ./scripts/50-setup-home.ps1 -WhatIf"
   - "same" → "Vše v pořádku. Můžeš spustit: ./menu/menu.ps1"
   - "os-changed" → "Reinstal detekován. Spusť: ./scripts/50-setup-home.ps1 -Force"
   - "tools-changed" → "Nová verze nástrojů. Spusť: ./scripts/70-test.ps1"

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
Read the report and `scripts/70-test.ps1` output. Categorize issues:

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
  scripts/60-repair.ps1 -WhatIf  (preview)
  scripts/60-repair.ps1 -Force   (apply)
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
5. "Start with: cd ~/.dev-env/repo && ./scripts/50-setup-{profile}.ps1 -WhatIf"
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
| 8 | **PowerShell 7+ required** | `40-profile.ps1` uses `??` operator — won't work on PS 5.1 |

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
→ 50-setup-work.ps1 handles:
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
  1. 50-setup-home.ps1 -Force (reinstall all packages)
  2. 60-repair.ps1 -Force (fix PATH, HOME)
  3. link-configs.ps1 -Force (restore config symlinks)
  4. 70-test.ps1 (verify everything)
```
