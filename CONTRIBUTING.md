# Contributing to dev-env

## 🧑‍💻 For Humans

### Before you start
1. Read `docs/architecture.md` to understand the pipeline
2. Run `./scripts/70-test.ps1` to verify current state
3. Always test with `-WhatIf` before making changes

### Making changes
1. Create a branch: `git checkout -b feat/my-change`
2. Follow the PowerShell conventions:
   - `[CmdletBinding(SupportsShouldProcess)]` for mutation scripts
   - Header pattern: `ROLE: / RUN: / INPUT: / OUTPUT:`
   - Bilingual comments (English functional, Czech context)
   - No aliases (`Get-ChildItem` not `ls`)
   - `Join-Path` instead of string concatenation
3. Update `AGENTS.md` if you change phases or add scripts
4. Test: `./scripts/99-validate-bootstrap.ps1 -Quick`
5. Commit: `git commit -m "popis změny"`
6. Push: `git push origin feat/my-change`

### Pull request checklist
- [ ] Tests pass: `./scripts/70-test.ps1`
- [ ] Validated: `./scripts/99-validate-bootstrap.ps1 -Quick`
- [ ] AGENTS.md updated if phases changed
- [ ] Header pattern present in new scripts
- [ ] `-WhatIf` tested before actual run

## 🤖 For AI Agents

1. Start with `AGENTS.md` — it contains the decision tree
2. Follow HARD RULES from `copilot-instructions.md`
3. Validate with `validate-agents.yml` locally:
   ```powershell
   pwsh -c "./scripts/70-test.ps1"
   pwsh -c "Get-ChildItem scripts/*.ps1 | ForEach-Object { if((Get-Content \$_ -First 10 -Raw) -notmatch 'ROLE:'){Write-Host 'MISSING HEADER: \$_'} }"
   ```
4. Never modify `~/.ssh/`, `~/.dev-env/config/`, or `machines.json`
5. Use `-WhatIf` for ALL destructive operations
