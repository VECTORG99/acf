# Security Policy

## Overview

ACF (Agent Context Forge) is a **skill system** — a collection of Markdown-based
skill definitions (`SKILL.md` files), templates, and documentation. It has
**no runtime, no server, no database, and no network listeners**. The attack
surface is minimal.

The primary security risk is **malicious `SKILL.md` content being executed by
an AI agent** that consumes the skill. Because skills are instructions read and
acted upon by agents, a compromised skill could instruct an agent to exfiltrate
data, modify files, or run destructive commands. We treat skill integrity as
the core security concern.

## Reporting a Vulnerability

**Do NOT open a public GitHub issue for security vulnerabilities.**

Instead, report vulnerabilities privately via **GitHub Security Advisories**:

1. Go to the repository's **Security** tab → **Advisories** → **Report a new advisory**
2. Provide a clear description, reproduction steps, and impact assessment
3. We will acknowledge receipt and coordinate a fix and disclosure timeline

If GitHub Security Advisories are unavailable to you, contact the maintainer
directly via a private channel. **Never disclose security vulnerabilities
publicly** until a fix has been released and a coordinated disclosure window
has passed.

## Response Timeline

| Severity | Priority | Target Response | Target Fix |
|----------|----------|-----------------|------------|
| Critical | P0 | ≤ 7 days | Next release / emergency patch |
| High | P1 | ≤ 14–21 days | Next release |
| Medium | P2 | Next release cycle | Next release |
| Low | P3 | As time permits | As time permits |

"Response" means acknowledgement + triage. "Fix" means a merged patch or
documented mitigation. Timelines are best-effort commitments from maintainers
working on this project in their available time.

## Supported Versions

ACF follows a single-major support model. Only the **current major** receives
security fixes.

| Version | Supported |
|---------|-----------|
| Current major | ✅ Yes |
| Previous majors | ❌ No |
| Pre-release / dev branches | ❌ No (best-effort only) |

## Security Features of ACF

ACF is designed to be safe by default. The following properties hold for the
canonical skill set shipped in this repository:

- **No secrets in skills** — `SKILL.md` files never contain API keys, tokens,
  passwords, or credentials. CI scans enforce this (see
  `.github/workflows/security-check.yml`).
- **No external API calls** — skills instruct agents to use local tools and
  the `gh` CLI only. No skill makes outbound HTTP calls to third-party APIs.
- **`gh` CLI only** — all GitHub interaction goes through the authenticated
  `gh` CLI using the user's own credentials and scopes. ACF never stores or
  handles tokens directly.
- **Local-only by default** — ACF operates on the local filesystem and the
  local git repository. There is no server component, no daemon, and no
  network listener.
- **Markdown-only** — the repository contains no executable runtime code, no
  `package.json`, and no dependencies to audit or update.

### Skill integrity

Because skills are agent instructions, the main threat model is a malicious or
tampered `SKILL.md`. Mitigations:

- Skill changes require review (see `.github/CODEOWNERS`).
- CI validates skill structure and scans for secrets on every push and PR.
- Users should only install skills from trusted sources and review skill
  content before an agent executes it.

## Safe Harbor

When reporting a vulnerability in good faith, we will not pursue legal action
against you. We ask that you:

- Avoid accessing or modifying data that is not yours.
- Avoid degrading or disrupting services (ACF has no hosted services, but this
  applies to any related infrastructure).
- Provide reasonable time for remediation before any public disclosure.
- Report through the private channels described above, not public issues.

We will credit reporters in release notes unless they prefer to remain
anonymous.
