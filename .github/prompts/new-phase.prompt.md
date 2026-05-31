---
description: "Create a new dev-env pipeline phase script from template. Use when: creating new phase scripts, adding pipeline steps, scaffolding phase XX scripts."
name: "new-phase"
argument-hint: "Phase number + description (e.g., 45-cache for caching layer)"
agent: "agent"
---
Create a new PowerShell phase script following the dev-env project conventions.

## Instructions

You are creating a new pipeline phase script: `scripts/{{PHASE}}-{{NAME}}.ps1`

### Exact Actions (numbered checklist — follow in order)

1. **Validate inputs**: PHASE must match regex `^\d{2,}$` (two or more digits, e.g., `45`). NAME must match `^[a-z0-9-]+$` (lowercase letters, digits, hyphens). If PHASE or NAME are missing or do not match these patterns, print `"ERROR: Invalid PHASE/NAME format. PHASE must be two or more digits; NAME must be lowercase letters/digits/hyphens."` and `exit 1`.
2. **Check for existing file**: If `scripts/{{PHASE}}-{{NAME}}.ps1` already exists, do NOT overwrite it. Print `"ERROR: scripts/{{PHASE}}-{{NAME}}.ps1 already exists. Aborting."` and `exit 1`.
3. **Determine COLOR**: Map PHASE to a `-ForegroundColor` using the `Colors by Phase Theme` table below. Ranges are inclusive on both ends (e.g., `10–20` covers 10, 11, …, 20). For any PHASE not listed, use `DarkCyan`.
4. **Derive LABEL and POPIS**: Set `{{LABEL}}` = Title-Case human-friendly label derived from NAME (replace hyphens with spaces, title-case each word, e.g. `'cache-layer'` → `'Cache Layer'`). Set `{{POPIS}}` = Czech translation of LABEL; if you cannot provide an accurate translation, set `{{POPIS}}` = `'<CZECH_TRANSLATION_NEEDED>'`.
5. **Render the header**: Use the exact format `Write-Host ">>> PHASE {{PHASE}} — {{LABEL}} / {{POPIS}}" -ForegroundColor {{COLOR}}`.
6. **Fill template placeholders**: Replace all `{{…}}` placeholders with concrete scaffolded content:
   - `{{STEP_TITLE}}`: A one-line descriptive title (English).
   - Detection steps: Include a commented `# TODO: implement detection` and a minimal detection snippet that uses `Write-Host` with emoji indicators (`✅ OK`, `❌ FAIL`, `⚠️ WARN`). Detection steps must have no external side effects.
   - Action steps: Include a commented `# TODO: implement action`, a `ShouldProcess` guard (`if ($PSCmdlet.ShouldProcess(...))`), and a `try/catch` block. Do NOT implement actual external side effects — leave those as TODO.
   - Footer: Fill `{{PHASE}}` and `{{LABEL}}` with the values derived above.
7. **Call create_file**: Call the `create_file` tool with `filename: "scripts/{{PHASE}}-{{NAME}}.ps1"` and the generated script as `content`. If `create_file` succeeds, output nothing else. If `create_file` returns an error, capture its error message, output the script content prefixed by the exact line: `"Tool create_file unavailable — outputting file content only."`, append the tool's error message on the next line, then `exit 1`.

### Edge Cases

| Situation | Behavior |
|-----------|----------|
| PHASE is single digit (e.g., `5`) | Reject — PHASE must be two or more digits |
| NAME contains uppercase or underscores | Reject — NAME must match `^[a-z0-9-]+$` |
| Target file already exists | Abort with error message and `exit 1` |
| `create_file` tool unavailable | Output script content with fallback message, `exit 1` |
| PHASE not in any color range | Use default `DarkCyan` |
| Czech translation unavailable | Set POPIS to `'<CZECH_TRANSLATION_NEEDED>'` |

### Template

Follow this exact structure:

```powershell
#!/usr/bin/env pwsh
# === scripts/{{PHASE}}-{{NAME}}.ps1 =========================================
# ROLE:   One-line English description / český popis
#         Detail line / detail
# RUN:    ./{{PHASE}}-{{NAME}}.ps1 [-WhatIf] [-Force]
# INPUT:  dependencies / inputs
# OUTPUT: what it produces
# ==============================================================
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Force,
    [switch]$WhatIf
)

Write-Host ">>> PHASE {{PHASE}} — {{LABEL}} / {{POPIS}}" -ForegroundColor {{COLOR}}
Write-Host ""

# 1. First step / první krok
Write-Host "{{PHASE}}.1 {{STEP_TITLE}}" -ForegroundColor Cyan
# TODO: implement detection — no external side effects
if ($condition) {
    Write-Host "  ✅  OK — {{description}}" -ForegroundColor Green
} else {
    Write-Host "  ❌  FAIL — {{description}}" -ForegroundColor Red
}

# 2. Second step — example with ShouldProcess
Write-Host "{{PHASE}}.2 {{STEP_TITLE}}" -ForegroundColor Cyan
# TODO: implement action
if ($PSCmdlet.ShouldProcess("{{target}}", "{{action}}")) {
    try {
        # TODO: implement actual action
        Write-Host "  ✅  Done / Hotovo" -ForegroundColor Green
    } catch {
        Write-Host "  ❌  FAIL: $_" -ForegroundColor Red
    }
}

# --- Footer ---
Write-Host ""
Write-Host ""
Write-Host ">>> {{PHASE}} — {{LABEL}} OK" -ForegroundColor Green
if ($Force)   { Write-Host "  Applied / Aplikováno" -ForegroundColor DarkGray }
if ($WhatIf)  { Write-Host "  Dry-run — review above then run with -Force" -ForegroundColor DarkGray }
if (-not $Force -and -not $WhatIf) { Write-Host "  Review above then run with -WhatIf or -Force" -ForegroundColor DarkGray }
Write-Host "=== DONE / HOTOVO ===" -ForegroundColor Green
```

### Conventions to Enforce

From the project's PowerShell conventions. Priority tiers (Mandatory / Recommended / Best-practice) are defined in the "Priority Checklist" section below; that checklist takes precedence over this summary table.

| Rule | Priority | Requirement |
|------|----------|-------------|
| Shebang | Mandatory | `#!/usr/bin/env pwsh` (first line) |
| Header | Mandatory | `# === scripts/XX-name.ps1 ====` block with ROLE, RUN, INPUT, OUTPUT |
| CmdletBinding | Mandatory | `[CmdletBinding(SupportsShouldProcess)]` for phase scripts |
| Bilingual | Mandatory | Every user-facing message must include English first, then Czech after a slash. Example: `"Done / Hotovo"`. In header fields include both: `ROLE: One-line English description / český popis`. |
| Phase header | Mandatory | `Write-Host ">>> PHASE XX — LABEL / POPIS" -ForegroundColor <color>` — where LABEL is the human-friendly English name and POPIS is the Czech translation (see "Exact Actions" step 4 for derivation rules). |
| Footer | Mandatory | Summary with `-Force` / `-WhatIf` guidance |
| Output | Mandatory | `Write-Host` for user messages; emoji indicators (✅ ❌ ⚠️ MISS) |
| Colors | Mandatory | Green=OK, Red=FAIL, Yellow=WARN/MISS, Cyan=section headers, DarkGray=meta |
| Exit code | Mandatory | Phase scripts: `0` = success; check scripts: `0` = pass, `1` = fail. On validation/abort errors: `exit 1`. |
| Error handling | Recommended | `$ErrorActionPreference = "Continue"` for detection; `try/catch {}` for risky operations |
| Paths | Best-practice | `Join-Path` only, `[Environment]::ExpandEnvironmentVariables()` for `~` |
| Data | Best-practice | `[ordered]@{}` for structured data |

### Colors by Phase Theme

| Phase range (inclusive) | Color | Example |
|--------------------------|-------|---------|
| 00 | DarkCyan | Prerequisites |
| 10–20 | Magenta | Detection / Report |
| 30 | DarkBlue | Clone |
| 40 | Blue | Profile |
| 50 | Green | Package setup |
| 60 | Yellow | Repair |
| 70 | Cyan | Validation |

Ranges are inclusive on both endpoints. For example, `10–20` covers phases 10, 11, 12, …, 20. If PHASE number is not covered by any listed range (including the single-value rows), use `-ForegroundColor DarkCyan` as the default.

### Priority Checklist

Follow these rules in priority order:

1. **Mandatory**: shebang `#!/usr/bin/env pwsh` (first line), header block with ROLE/RUN/INPUT/OUTPUT, `[CmdletBinding(SupportsShouldProcess)]`, footer with `-Force`/`-WhatIf` guidance, bilingual English/Czech in every user-facing message (English first, Czech after slash).
2. **Recommended**: `$ErrorActionPreference = "Continue"` for detections; `try/catch {}` for risky operations; `exit 1` on any validation or abort failure.
3. **Best-practice**: use `Join-Path` for paths, `[ordered]@{}` for data.

### Anti-patterns to Avoid

- ❌ No aliases (`ls`, `gc`, `%`, `?` — use full cmdlet names)
- ❌ No `~` or `$HOME` — use `$env:USERPROFILE` or `[Environment]::ExpandEnvironmentVariables()`
- ❌ No path string concatenation (`$base + "/" + $name`) — use `Join-Path`
- ❌ No global `$ErrorActionPreference = "Stop"` — use `"Continue"` with local `try/catch`
- ❌ No install without `ShouldProcess` guard
- ❌ No silent failures — always `Write-Host` the outcome

### Profile Integration

If the script is profile-specific, add profile dispatch logic:

```powershell
$profileName = $args[0]  # or detect from input
if (-not $profileName) {
    Write-Host "  ❌  Profile name required / Je potřeba jméno profilu" -ForegroundColor Red
    exit 1
}
```

### Output

1. **If `scripts/{{PHASE}}-{{NAME}}.ps1` already exists**, do NOT overwrite it. Print `"ERROR: scripts/{{PHASE}}-{{NAME}}.ps1 already exists. Aborting."` and `exit 1`.
2. **If the target file does not exist**, generate ONLY the script file content (no additional explanatory text in your response). Then call the `create_file` tool with `filename: "scripts/{{PHASE}}-{{NAME}}.ps1"` and the generated script content as `content`.
3. **If the `create_file` tool is unavailable or returns an error**, capture the tool's error message, output the script content prefixed by the exact line: `"Tool create_file unavailable — outputting file content only."`, append the tool's error message on the next line, then `exit 1`.

After creating, update the phase table in relevant docs if needed (suggest, don't auto-edit).
