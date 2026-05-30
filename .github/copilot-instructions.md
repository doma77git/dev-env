# dev-env — GitHub Copilot Instructions

> Located at `.github/copilot-instructions.md` — auto-loaded by GitHub Copilot.
> The **authoritative** agent instructions are at `copilot-instructions.md` (repo root).
> This file supplements with GitHub-specific context.

---

## Repository Context

- **Owner**: doma77git
- **Repo**: dev-env
- **Default branch**: master
- **GitHub Pages**: https://doma77git.github.io/dev-env
- **Gist entry point**: https://gist.github.com/doma77git/2f489d9ce5e7e0ff75b17cbe8011bbb5

## Copilot Chat Configuration

When using GitHub Copilot Chat in this repo:

1. **Agent instructions** are loaded from `copilot-instructions.md` (hard rules + preferences)
2. **AI context** is available at `ai/context.md` (full lifecycle, decision tree, prompts)
3. **Chat history** is documented at `ai/copilotchat.md`
4. **JSON Schema** for reports is at `ai/schema.json`

## Custom Agents

This repo defines custom agents in `.github/agents/`:
- **`ps-review`** — Reviews PowerShell scripts against dev-env conventions

## Custom Prompts

This repo defines reusable prompts in `.github/prompts/`:
- **`new-phase`** — Creates a new pipeline phase script from template

## Instructions Files

Language-specific coding conventions:
- `.github/instructions/powershell.instructions.md` — PowerShell cmdlet best practices
- `.github/instructions/pwsh-script-standards.instructions.md` — dev-env script standards

## PR & Issue Workflow

- CI runs on push to `master` (`.github/workflows/ci.yml`)
- PR validation runs on PR open/sync (`.github/workflows/pr.yml`)
- Gist auto-syncs on release (`.github/workflows/gist-sync.yml`)

## Key Constraints for Copilot

- NEVER suggest `winget install`, `npm install -g`, or similar without user confirmation
- NEVER suggest committing secrets or PII
- Always use full PowerShell cmdlet names (no aliases)
- All mutations must go through `ShouldProcess` / `-WhatIf` pattern
- Phase scripts follow the `00→30→10→20→40→50→60→70` pipeline order
