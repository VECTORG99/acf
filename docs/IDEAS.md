# Ideas — Source Conversation Analysis

This document captures the ideas from the conversation between `lil. vector` and
`D4MAG3` (31/7/26) that inspired ACF, and maps each idea to its
implementation in the skill architecture.

## Original Conversation (summarized)

### Idea 1: Issues with rich context

> "siento que los issues deben de tener un criterio que ayude el contexto del pr"
> "que tengan mas contexto del proyecto, que mande al issue y el pr tengan contexto
> actualizado del stack, el criterio de los checks y en si las pruebas"

**Implementation**: Phase 1 (context-load) reads all project MDs and builds a
compressed snapshot. Phase 3 (issue-craft) uses that snapshot to write AC that
reference real test commands and CI check names. Phase 4 (pr-context) carries
that context into the PR body.

### Idea 2: Pre-read prompt before the issue

> "de tal forma de que sea mas facil para la ia encontrar la informacion para que
> el pr pase sin problemas. el issue tenga un armado rico en contexto y para ello
> antes del issue lea siempre un prompt q vea este contexto"

**Implementation**: Context-load IS the pre-read prompt. It runs before
issue-craft and produces the snapshot that issue-craft consumes.

### Idea 3: Skill, not agent

> "yo creo que reduciria alucinaciones y pasarian mas rapidos los checks, pero un
> agente es un monton, yo creo que un skill es suficiente"

**Implementation**: ACF is a single orchestrator skill with 6 sub-skills.
No separate agent process. It runs within the existing agent session (Devin,
OpenCode, Claude Code, etc.).

### Idea 4: Stack audit (open PRs, unclosed issues)

> "intento darle ese contexto de que antes de desarrollar un pr que revise si hay
> un pr que aun este abierto que no este mergeado y cerrado el issue, o que el pr
> ya haya sido mergeado y el issue no haya sido cerrado tambien, o prs que no
> referencian issues"

**Implementation**: Phase 2 (stack-audit) checks for:
- Orphan PRs (no issue reference)
- Stale issues (ready but no PR)
- Merged PR + issue still open
- Closed issue + no merged PR

### Idea 5: Library suggestions as separate issues

> "issues que se escapan del stack actual que tambien podrian mejorar con una
> libreria que deberia llevarse hacerse un pr para una revision al respecto de la
> libreria y se deje documentado"

**Implementation**: Stack-audit identifies library opportunities. Issue-craft
creates a **separate enhancement issue** with `library-review` label. The main
issue references it: `Related: #NN (library review)`.

### Idea 6: Frontend preview trigger

> "se podria realizar lo que en kiro es un hook pero en efectos practicos es un
> skill como trigger que lance una vista en local con los cambios hechos con la
> vision del mismo, se cambia un color en contributors va a localhost/contributors
> y te deja sobre el cambio con lo que deberia haber cambiado"

**Implementation**: Phase 5 (frontend-preview) is an optional trigger that:
- Detects affected routes from the diff
- Launches/reuses the dev server
- Navigates to the affected route
- Captures before/after screenshots
- Produces a visual diff (red/green overlay)

### Idea 7: Vision models for screenshots

> "eso con modelos que tienen vision tambien podria ejecutar una captura de pantalla"

**Implementation**: Frontend-preview captures a screenshot and attaches it to
the PR. Vision-capable models can review the visual change.

### Idea 8: Visual diff like git

> "Lo rojo es lo eliminado y lo verde lo nuevo. Imaginate eso pero en la web"

**Implementation**: Frontend-preview produces a before/after overlay with
removed regions in red and added regions in green, mimicking `git diff` but for
rendered web pages.

### Idea 9: Labels and metadata over body text

> "apoyense de los labels y metadata, que no sea solo texto en el body de los
> issues/pr, es más fácil para las automatizaciones y también ahorra tokens, leer
> mucho texto no es optimo para encontrar cosas"

**Implementation**: Sub-skill 06 (label-metadata) defines a canonical taxonomy
(type, priority, area, status, enhancement). Every issue and PR uses structured
labels as the primary index. Body text is minimal and secondary.

### Idea 10: Full compressed flow

> "que cada parte del flujo tenga la suficiente informacion (agente ejecuta skill
> > lee todos los mds > aprende de la aquitectura y el desafio del software, aprende
> > sobre los templates y los test > tiene contexto de posibles issues (investiga)
> > (puede sugerir librerias que faciliten las soluciones) > arma el issue
> > contextualizado con criterios (si hay una nueva posible libreria se deja como un
> > issue aparte como enhancement) > el contexto se lee para el pr con conocimiento
> > de los test > el pr se lanza) a poder ser comprimida el contexto"

**Implementation**: This is the exact ACF pipeline:
1. context-load (lee MDs, aprende arquitectura + templates + tests)
2. stack-audit (investiga issues, sugiere librerías)
3. issue-craft (arma issue contextualizado, librería → issue aparte)
4. pr-context (contexto para PR con conocimiento de tests)
5. launch (PR se lanza)
6. Context is compressed at every step (paths, not contents)

### Idea 11: Frontend trigger as a skill, not IDE hook

> "lo que si deberia poderse dejar es un trigger q lance el frontend cuando el
> cambio lo requiere"

**Implementation**: Frontend-preview is a skill phase, not an IDE hook. It
triggers based on the diff content (frontend files detected), not on an IDE
event. This makes it portable across editors.

### Idea 12: Context compaction (Kimi CLI-inspired)

> "necesito que veas como comprime kimi y compacta para el prompt y gastar
> menos tokens, creo que era kimi o un modelo opensource de ia que lo hacia
> y lo dejo publico recientemente investiga y sigue el ciclo"

**Implementation**: Phase 7 (compaction) adapts Kimi CLI's open-source
compaction system ([MoonshotAI/kimi-cli](https://github.com/MoonshotAI/kimi-cli)).
Four key techniques are borrowed:
1. **Tail-preservation** — keep recent phase output verbatim, compact older
2. **Priority-based compression** — preserve task state, errors, test commands,
   CI checks; compress architecture and conventions
3. **XML-tagged output** — `<current_focus>`, `<stack>`, `<tests>`, `<ci>`,
   `<architecture>`, `<conventions>`, `<completed_phases>`
4. **First-person handoff** — progress file reads as agent's own working notes

See [docs/COMPACTION.md](COMPACTION.md) for the full research and design notes.

### Idea 13: Caveman mode (extreme token compression)

> "y un posible caveman"

**Implementation**: Phase 8 (caveman) is original to ACF, taking Kimi's
compression rules to their logical extreme. Target: <500 tokens for the
entire snapshot. Principles: no prose, symbols over words, counts not lists,
bare caveman last resort (~100 tokens). Caveman is a separate phase from
compaction because it serves a different need: "I have almost no context
budget, give me the bare minimum" vs compaction's "I have too much context
but I still need structure".

## Ideas Not Yet Implemented (Future)

### Continuous stack monitoring
> "revisar si hay un pr que aun este abierto"

Currently stack-audit runs on-demand. A future version could run on a timer
(like homedir's 3-minute worker) for continuous monitoring.

### Cross-repo stack audit
Stack-audit currently works within a single repo. A future version could audit
across multiple repos in a monorepo or org.

### Automated issue decomposition
> "Complex issues may need human review or staged delivery"

Currently issue-craft flags Complex issues for decomposition. A future version
could automatically split a Complex issue into child issues.
