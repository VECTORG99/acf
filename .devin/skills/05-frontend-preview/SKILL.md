---
name: frontend-preview
description: >-
  Phase 5 of ContextForge (optional). Launches a local frontend preview of the
  changes, produces a visual diff (before/after, like git red/green but on the
  web), and optionally captures a screenshot for vision-model review. Use when
  ContextForge detects frontend changes, or when the user asks to "preview the
  frontend", "see the visual diff", or "screenshot the change".
---

# Frontend-Preview

Provides visual verification for frontend changes before a PR is opened. This is
the "kiro hook" equivalent implemented as a skill trigger.

## When to Trigger

Trigger frontend-preview when the diff touches:
- `*.html`, `*.css`, `*.scss`, `*.tailwind`
- `*.tsx`, `*.jsx`, `*.vue`, `*.svelte`
- `*.astro`, `*.njk`, `*.hbs`
- Any file under `frontend/`, `src/components/`, `templates/`, `views/`

## Workflow

### 1. Detect Affected Routes

From the diff, infer which routes/pages are affected:
- File `src/pages/contributors.tsx` → route `/contributors`
- File `src/components/Navbar.tsx` → all routes (global component)
- File `src/styles/theme.css` → all routes

### 2. Launch Dev Server (if not running)

```bash
# Detect the dev command from package.json or project config
npm run dev  # or: pnpm dev, yarn dev, bun dev
```

If a dev server is already running (check common ports: 3000, 5173, 8080),
use it instead of starting a new one.

### 3. Navigate to Affected Route

Use Playwright (or the browser preview tool) to:
1. Navigate to the affected route (e.g., `http://localhost:3000/contributors`)
2. Capture a **screenshot of the current (changed) state**

### 4. Visual Diff (Before/After)

To produce a git-style visual diff on the web:

1. **Before**: `git stash` the changes, screenshot the route, `git stash pop`
2. **After**: screenshot the route with changes applied
3. **Diff**: overlay the two screenshots, highlighting changed regions in
   red (removed) / green (added)

This mimics `git diff` but for rendered web pages.

**Stash safety:** only run the stash/pop pair when the working tree is clean
enough that `git stash pop` cannot conflict (no untracked files that the stash
would clobber, no overlapping staged changes). If `git stash pop` reports
conflicts, stop and surface the conflict to the user — do not force-resolve.
Prefer `git stash --include-untracked` only when explicitly safe, and always
verify `git status` is back to the pre-stash state before continuing.

### 5. Screenshot for Vision Review

Capture a screenshot and attach it to the PR so vision-capable models can
review the visual change:

```bash
# Save screenshot
playwright screenshot --url http://localhost:3000/contributors \
  --output /tmp/frontend-preview.png
```

The screenshot is referenced in the PR body:
```markdown
## Frontend Preview
![Preview](screenshot-url-or-attachment)
```

## Lightweight Mode

If Playwright or a dev server is not available, frontend-preview degrades to:
- Listing the affected routes
- Describing the expected visual change based on the diff
- Recommending manual verification

Do NOT block the PR on frontend-preview — it's an enhancement, not a gate.

## Integration with PR-Context

If frontend-preview was run:
- Add a `## Frontend Preview` section to the PR body
- Attach the screenshot
- Add an AC checkbox: `- [ ] Visual change verified on /route`

If frontend-preview was NOT run (no frontend changes):
- Skip this phase entirely
