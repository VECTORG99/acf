# ACF — Roadmap

> Product maturity assessment and forward plan.
> Last updated: 2026-08-04

## Current Phase: Alpha (v0.3)

ACF is in **alpha**. The core architecture is sound, the 8-phase pipeline is
designed, all skills are documented, and the test suite now covers the
installer, validator, integration, and compaction benchmark. The system has
not been battle-tested in production across multiple real projects, and the
multi-agent compatibility layer needs manual verification on each agent.

## Maturity Assessment

| Dimension | Status | Score (1-5) | Notes |
|-----------|--------|-------------|-------|
| Architecture | Done | 4 | deepwork+oracle pattern, 8 phases, clear data flow |
| Skill content | Done | 3 | All 8 SKILL.md written, but not iteratively tested |
| Multi-agent compat | In progress | 2 | install.sh + agentskills.io compliance added, not tested on all agents |
| Security | In progress | 2 | SECURITY.md, CI secret scan added, no audit done |
| Testing | Done | 3 | 4 test suites (validate, install, integration, benchmark) — 35 tests passing |
| Documentation | Done | 4 | 7 docs (ARCHITECTURE, FLOW, IDEAS, PROCESS, COMPACTION, COMPATIBILITY, ROADMAP) |
| Compaction | Benchmarked | 4 | Kimi-inspired design + benchmark: 284 tokens compacted (98% savings) |
| Caveman | Benchmarked | 4 | Extreme compression + benchmark: 64 tokens caveman, 26 bare (99% savings) |
| Adoption | Not started | 1 | Issue created for artemisa/homedir, no actual installs |
| Metrics | Partial | 2 | Compaction benchmark exists (98-99% savings), no CI-pass-rate tracked yet |
| Community | Not started | 1 | No contributors, no marketplace listing, no awesome-list presence |
| **Overall** | **Alpha** | **2.8/5** | **Solid foundation, tests + benchmarks done, needs adoption** |

## Distance to First-Class Product

A "first-class product" in the AI coding skill space means:
- Tested across 5+ real projects with measured outcomes
- Compatible with 5+ agents (Claude Code, Cursor, Codex, OpenCode, Devin)
- Listed on awesome-claude-skills and similar registries
- Has metrics: token savings, CI pass rate improvement, time-to-PR reduction
- Has community contributors and a governance process
- Has a stable v1.0 with semantic versioning

**Current distance: ~65% of the way to v1.0.**

What we have (the 65%):
- Complete architecture and skill design
- Compaction and caveman (the key differentiators) — now benchmarked
- Multi-agent compatibility layer (6 agents, tested installer)
- Security baseline (SECURITY.md, CI secret scan, CODEOWNERS)
- Comprehensive documentation (7 docs)
- Test suite: 35 tests across 4 suites (validate, install, integration, benchmark)
- Compaction benchmark: 98% savings (compacted), 99% (caveman/bare)

What we need (the remaining 35%):
- Real-world testing with measured outcomes on actual projects
- Manual verification on each of the 6 agents (trigger behavior)
- Adoption in artemisa, homedir, and 2+ external projects
- Community presence (awesome-lists, blog posts, demos)
- Iterative skill improvement based on usage data
- v1.0 release with stable API

## Roadmap

### Phase 1: Alpha Stabilization (current — v0.3 → v0.4)

**Goal**: Make ACF testable and installable across all agents.

- [x] 8-phase pipeline designed and documented
- [x] Compaction (phase 7) — Kimi CLI-inspired
- [x] Caveman (phase 8) — extreme compression
- [x] Multi-agent compatibility (install.sh, agentskills.io spec)
- [x] Security baseline (SECURITY.md, CI secret scan, CODEOWNERS)
- [x] Skill validation CI (validate-skills.sh)
- [x] Test suite: installer, validator, integration, benchmark (35 tests)
- [x] Benchmark: compaction 98% savings, caveman 99% savings (measured)
- [ ] Test install on Claude Code, Cursor, Codex, OpenCode, Devin (manual)
- [ ] Fix any spec compliance issues found during testing

### Phase 2: Beta — Real-World Testing (v0.3 → v0.5)

**Goal**: Prove ACF works in real projects with measured outcomes.

- [ ] Adopt ACF in artemisa (full pipeline, compaction, caveman)
- [ ] Adopt ACF in homedir (stack-audit, label-metadata)
- [ ] Adopt ACF in 2+ external projects (different stacks)
- [ ] Collect metrics: token usage, CI pass rate, time-to-PR, alucination rate
- [ ] Iterate on skill content based on real usage
- [ ] Add head+tail preservation (from Kimi Code PR #1313)
- [ ] Add compaction metrics tracking
- [ ] Frontend-preview: test with real Playwright on a React/Vue project

### Phase 3: Community (v0.5 → v0.8)

**Goal**: Build presence and attract contributors.

- [ ] List on awesome-claude-skills, awesome-claude-code-and-skills
- [ ] Write a blog post / demo video showing ACF in action
- [ ] Create a benchmark report (token savings, CI pass rate)
- [ ] Add CONTRIBUTING.md governance (done — iterate based on feedback)
- [ ] First external contributor
- [ ] Marketplace listing (Agensi or similar)
- [ ] Cross-agent compatibility matrix (tested on N agents)

### Phase 4: v1.0 — Production Ready

**Goal**: Stable, tested, community-validated.

- [ ] Semantic versioning (v1.0.0)
- [ ] Stable skill API (no breaking changes without major version bump)
- [ ] 10+ adopted projects with reported outcomes
- [ ] 5+ community contributors
- [ ] Full benchmark suite (compaction, caveman, CI pass rate, token savings)
- [ ] Security audit completed
- [ ] Cross-agent compatibility tested and documented
- [ ] v1.0 release blog post / announcement

### Phase 5: v1.x — Expansion

**Goal**: Extend ACF beyond issue/PR crafting.

- [ ] Continuous stack monitoring (timer-based, like homedir's worker)
- [ ] Cross-repo stack audit (monorepo / org level)
- [ ] Automated issue decomposition (Complex → child issues)
- [ ] MCP server for ACF (so any agent can use it via MCP)
- [ ] ACF-as-a-service (web UI for crafting issues/PRs)
- [ ] Integration with GitHub Actions (auto-label, auto-validate on issue create)
- [ ] Multi-language support (Spanish, Portuguese, English — already partial)

## What We Need

### Immediate (to exit alpha)

1. **Testers** — install ACF on Claude Code, Cursor, Codex, OpenCode, and Devin.
   Report what works, what breaks, what's unclear.

2. **Benchmark data** — run ACF on a real issue/PR and measure:
   - Token usage: full vs compacted vs caveman
   - Time to craft the issue/PR
   - CI pass rate on first try

3. **Real projects** — adopt ACF in artemisa, homedir, and 2+ external projects.
   Report lessons learned, gaps, feature requests.

### Medium-term (to exit beta)

4. **Community contributors** — review skills, suggest improvements, add
   edge-case handling, write tests for skill behavior.

5. **Awesome-list presence** — submit to awesome-claude-skills and similar
   registries for discoverability.

6. **Blog post / demo** — show ACF in action so others can see the value.

### Long-term (to v1.0)

7. **Security audit** — formal review of the skill system for prompt injection,
   malicious skill content, and supply chain risks.

8. **Marketplace listing** — Agensi or similar for one-click install.

9. **MCP server** — so ACF works with any MCP-compatible agent, not just those
   that support the SKILL.md format.

## Competitive Landscape

| Product | Type | Compaction | Multi-agent | Status |
|---------|------|-----------|-------------|--------|
| ACF | Issue/PR crafting skill | Yes (Kimi + caveman) | Yes (6 agents) | Alpha |
| deepwork | Orchestrator workflow | No | OpenCode | Stable |
| Kimi CLI compaction | Context compaction | Yes (Kimi-native) | Kimi only | Stable |
| flitzrrr/frontend-design-skills | Frontend design | No | Multi-agent | Stable |
| Agensi marketplace skills | Various | Varies | Multi-agent | Stable |
| Claude Code skills (official) | Various | No | Claude only | Stable |

**ACF's differentiators**:
1. Only skill that combines issue/PR crafting + context compaction + caveman
2. Kimi-inspired compaction adapted for SDLC (not just conversation history)
3. Caveman extreme compression (original, not from Kimi)
4. Multi-agent from day one (not Claude-only or OpenCode-only)
5. Label-metadata as primary retrieval (not free-text body)

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Skills don't trigger correctly on some agents | Medium | High | Test on each agent, fix description keywords |
| Compaction loses critical context | Medium | High | Benchmark, add head+tail preservation |
| Caveman too aggressive, issues missing context | Low | Medium | Document what caveman loses, make it opt-in |
| Agent Skills spec changes | Low | Medium | Follow agentskills.io, update when spec updates |
| Kimi CLI compaction evolves, ACF falls behind | Low | Low | ACF adapts techniques, doesn't depend on Kimi code |
| No adoption | High | High | Test in artemisa/homedir first, then publish broadly |
| Prompt injection via malicious SKILL.md | Low | High | Security audit, CODEOWNERS, CI secret scan |

## Versioning

ACF follows semantic versioning:

- **v0.x**: Alpha — breaking changes possible between minor versions
- **v1.x**: Stable — breaking changes require major version bump
- **v1.x.y**: Patch — bug fixes, skill content improvements

Current: **v0.3.0**
