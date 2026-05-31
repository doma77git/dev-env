# 🔒 Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest (v1.1.0+) | ✅ Active development |
| Older versions | ❌ Not supported |

## 🛡️ What We Protect

| Asset | Protection |
|-------|-----------|
| SSH private keys (`~/.ssh/id_*`) | In `.gitignore`, backup only `.pub` files |
| Git identity (`~/.gitconfig.user`) | In `.gitignore`, never committed |
| Cloud tokens (`~/.npmrc`, `~/.aws/`, `~/.azure/`) | In `.gitignore`, never accessed by scripts |
| Machine history (`~/.dev-env/machines.json`) | In `.gitignore`, never sent externally |

## 🚨 Reporting a Vulnerability

**If you find a security issue:**
- **DO NOT** open a public GitHub issue
- **DO** email: `doma77@outlook.cz`
- Expected response: within 48 hours

### What to include:
- Description of the vulnerability
- Steps to reproduce
- Affected files/versions
- Potential impact

## 🔍 Security Audit History

| Date | Scope | Result |
|------|-------|--------|
| 2026-05-31 | Full code review | No `iex`, `HKLM`, or `DownloadString` found |
| 2026-05-31 | Dependency check | Only winget + git — no external packages |
| 2026-05-31 | Secrets scan | No credentials in repo |

## ✅ Safe Harbor

We commit to:
- Not pursuing legal action for good-faith security research
- Public acknowledgment for valid reports (with your consent)
- Prompt remediation of confirmed vulnerabilities

## 📚 See Also

- `docs/security.md` — detailed security mechanisms
- `AGENTS.md#HARD-RULES` — AI agent security rules
- `profiles/base.json#/secrets` — canonical secrets list
