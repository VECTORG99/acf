---
name: label-metadata
description: >-
  Cross-cutting skill for ACF. Defines the label and metadata taxonomy
  that replaces free-text body content as the primary retrieval mechanism. Use
  when ACF needs to assign labels to issues or PRs, or when the user
  asks about "label conventions", "issue metadata", or "taxonomy".
---

# Label & Metadata

Labels are the primary index for automation and retrieval. Body text is
secondary context. This skill defines the canonical taxonomy.

## Why Labels Over Text

1. **Token efficiency** — a label `priority:P0` is 4 tokens; "Priority: Critical,
   needs fix within 4 hours" is 15+ tokens
2. **Automation-friendly** — GitHub Actions and workers can filter by label
   without parsing body text
3. **Searchable** — `gh issue list --label "priority:P0"` is instant; searching
   body text is slow and error-prone
4. **Consistent** — labels are enumerated; body text is free-form and drifts

## Canonical Taxonomy

### Type Labels (what kind of change)

| Label | Color | Description |
|-------|-------|-------------|
| `bug` | `#d73a4a` | Something doesn't work as expected |
| `enhancement` | `#a2eeef` | New feature or improvement |
| `documentation` | `#0075ca` | Docs-only change |
| `refactor` | `#1d76db` | Code reorganization, no behavior change |
| `chore` | `#c5def5` | Build, CI, deps, tooling |
| `test` | `#0e8a16` | Test additions or infrastructure |
| `security` | `#b60205` | Security fix or hardening |

### Priority Labels (SLA urgency)

| Label | Color | SLA | Description |
|-------|-------|-----|-------------|
| `priority:P0` | `#b60205` | <4h | Critical: crash, exploit, data loss |
| `priority:P1` | `#d93f0b` | <48h | High: important bug, security gap |
| `priority:P2` | `#fbca04` | <1 week | Medium: degraded feature, refactor |
| `priority:P3` | `#0e8a16` | <1 month | Low: code quality, cosmetic |

### Area Labels (where in the stack)

| Label | Color | Description |
|-------|-------|-------------|
| `area:backend` | `#1d76db` | Server, API, services |
| `area:frontend` | `#c5def5` | UI, components, styles |
| `area:ci` | `#e4e669` | CI/CD, workflows, automation |
| `area:docs` | `#0075ca` | Documentation |
| `area:security` | `#b60205` | Security, auth, validation |
| `area:devops` | `#6e40c9` | Infrastructure, deployment |

### Status Labels (workflow state)

| Label | Color | Description |
|-------|-------|-------------|
| `ready-to-implement` | `#0e8a16` | Ready for autonomous/human work |
| `needs-metadata` | `#fbca04` | Issue missing required fields |
| `blocked` | `#b60205` | Blocked by dependency |
| `needs-human` | `#b60205` | Requires human decision |

### Enhancement Labels

| Label | Color | Description |
|-------|-------|-------------|
| `library-review` | `#5319e7` | Evaluate a library/dependency |
| `batch-delivery` | `#fbca04` | Issue has >2 AC, needs decomposition |

## Required Labels per Issue

Every issue MUST have at minimum:
- 1 **type** label
- 1 **priority** label
- 1 **area** label

Status labels are optional at creation time. `ready-to-implement` is added when
the issue is ready for work.

## Required Labels per PR

PRs inherit labels from their issue. Additionally:
- PRs should NOT have `ready-to-implement` (that's for issues)
- PRs can have `area:*` labels for filtering

## Setup

To create all labels in a repo:

```bash
# Type labels
gh label create "bug" --color "D73A4A" --description "Something doesn't work"
gh label create "enhancement" --color "A2EEEF" --description "New feature or improvement"
gh label create "documentation" --color "0075CA" --description "Docs-only change"
gh label create "refactor" --color "1D76DB" --description "Code reorganization"
gh label create "chore" --color "C5DEF5" --description "Build, CI, deps, tooling"
gh label create "test" --color "0E8A16" --description "Test additions"
gh label create "security" --color "B60205" --description "Security fix"

# Priority labels
gh label create "priority:P0" --color "B60205" --description "Critical, <4h SLA"
gh label create "priority:P1" --color "D93F0B" --description "High, <48h SLA"
gh label create "priority:P2" --color "FBCA04" --description "Medium, <1 week SLA"
gh label create "priority:P3" --color "0E8A16" --description "Low, <1 month SLA"

# Area labels
gh label create "area:backend" --color "1D76DB" --description "Server, API, services"
gh label create "area:frontend" --color "C5DEF5" --description "UI, components, styles"
gh label create "area:ci" --color "E4E669" --description "CI/CD, workflows"
gh label create "area:docs" --color "0075CA" --description "Documentation"
gh label create "area:security" --color "B60205" --description "Security, auth"
gh label create "area:devops" --color "6E40C9" --description "Infrastructure"

# Status labels
gh label create "ready-to-implement" --color "0E8A16" --description "Ready for work"
gh label create "needs-metadata" --color "FBCA04" --description "Missing required fields"
gh label create "blocked" --color "B60205" --description "Blocked by dependency"
gh label create "needs-human" --color "B60205" --description "Requires human decision"

# Enhancement labels
gh label create "library-review" --color "5319E7" --description "Evaluate a library"
gh label create "batch-delivery" --color "FBCA04" --description ">2 AC, needs decomposition"
```

## Metadata in Issue Body (minimal)

The body should contain **only** what labels can't express:
- Summary (1-2 sentences)
- Affected files (paths)
- Acceptance criteria (checkboxes)
- Validation command

Everything else (type, priority, area, status) goes in labels.
