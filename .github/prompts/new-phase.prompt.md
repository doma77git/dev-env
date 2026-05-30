---
description: "Create a new dev-env pipeline phase script from template. Use when: creating new phase scripts, adding pipeline steps, scaffolding phase XX scripts."
name: "new-phase"
argument-hint: "Phase number + description (e.g., 45-cache for caching layer)"
agent: "agent"
---
Create a new PowerShell phase script following the dev-env project conventions.

## Instructions

You are creating a new pipeline phase script: `scripts/{{PHASE}}-{{NAME}}.ps1`

**Input validation**: PHASE must match regex `^\d{2,}$` (two or more digits, e.g., `45`). NAME must match `^[a-z0-9-]+$` (lowercase letters, digits, hyphens). If PHASE or NAME are missing or do not match these patterns, abort with message: `"ERROR: Invalid PHASE/NAME format. PHASE must be two or more digits; NAME must be lowercase letters/digits/hyphens."` and exit non-zero.

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
# ... detection logic ...
if ($condition) {
    Write-Host "  ✅  OK — {{description}}" -ForegroundColor Green
} else {
    Write-Host "  ❌  FAIL — {{description}}" -ForegroundColor Red
}

# 2. Second step — example with ShouldProcess
Write-Host "{{PHASE}}.2 {{STEP_TITLE}}" -ForegroundColor Cyan
if ($PSCmdlet.ShouldProcess("{{target}}", "{{action}}")) {
    try {
        # ... action ...
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

From the project's PowerShell conventions:

| Rule | Requirement |
|------|-------------|
| Shebang | `#!/usr/bin/env pwsh` (first line) |
| Header | `# === scripts/XX-name.ps1 ====` block with ROLE, RUN, INPUT, OUTPUT |
| CmdletBinding | `[CmdletBinding(SupportsShouldProcess)]` for phase scripts |
| Error handling | `$ErrorActionPreference = "Continue"` for detection; `try/catch {}` for risky operations |
| Output | `Write-Host` for user messages; emoji indicators (✅ ❌ ⚠️ MISS) |
| Paths | `Join-Path` only, `[Environment]::ExpandEnvironmentVariables()` for `~` |
| Data | `[ordered]@{}` for structured data |
| Bilingual | Every user-facing message must include English first, then Czech after a slash. Example: `"Done / Hotovo"`. In header fields include both: ROLE: One-line English description / český popis. |
| Phase header | `Write-Host ">>> PHASE XX — NAME" -ForegroundColor <color>` |
| Footer | Summary with -Force/-WhatIf guidance |
| Colors | Green=OK, Red=FAIL, Yellow=WARN/MISS, Cyan=section headers, DarkGray=meta |
| Exit code | Phase scripts: 0 = success; check scripts: 0=pass, 1=fail |

### Colors by Phase Theme

| Phase range | Color | Example |
|-------------|-------|---------|
| 00 | DarkCyan | Prerequisites |
| 10-20 | Magenta | Detection / Report |
| 30 | DarkBlue | Clone |
| 40 | Blue | Profile |
| 50 | Green | Package setup |
| 60 | Yellow | Repair |
| 70 | Cyan | Validation |

If PHASE number is not covered by the table, set `-ForegroundColor DarkCyan` as the default.

### Priority Checklist

Follow these rules in priority order:

1. **Mandatory**: shebang `#!/usr/bin/env pwsh` (first line), header block with ROLE/RUN/INPUT/OUTPUT, `[CmdletBinding(SupportsShouldProcess)]`, footer with `-Force`/`-WhatIf` guidance.
2. **Recommended**: `$ErrorActionPreference = "Continue"` for detections; `try/catch {}` for risky operations.
3. **Best-practice**: use `Join-Path` for paths, `[ordered]@{}` for data, bilingual English/Czech in messages (English functional, Czech context).

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

1. **If `scripts/{{PHASE}}-{{NAME}}.ps1` already exists**, do NOT overwrite it. Abort and return the error: `"ERROR: scripts/{{PHASE}}-{{NAME}}.ps1 already exists. Aborting."`
2. **If the target file does not exist**, generate ONLY the script file content (no additional explanatory text in your response). Then call the `create_file` tool with filename `scripts/{{PHASE}}-{{NAME}}.ps1` and the generated script content.
3. **If the `create_file` tool is unavailable or returns an error**, output the script content only and include: `"Tool create_file unavailable — outputting file content only."`

After creating, update the phase table in relevant docs if needed (suggest, don't auto-edit).
