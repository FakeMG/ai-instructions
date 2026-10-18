---
name: reviewing-code-architecture
description: >
  This skill is for reviewing the *architecture* of a system, not just the code.
  Only trigger when the user is explicitly requesting this skill. Otherwise, don't use it.
---

# Code Architecture Review Skill

Use this skill for an unusually strict review focused on implementation quality, maintainability, abstraction quality, and codebase health.

**Before starting, read and follow the `multi-agent-review` skill (`../multi-agent-review/SKILL.md`).** It defines how sub-agents are spawned, how their reports are synthesized, and the required output format. This skill supplies the inputs that skill requires, listed below.

Above all, this skill should push the reviewer to be ambitious about code structure. Do not merely identify local cleanup opportunities. Actively search for "code judo" moves: restructurings that preserve behavior while making the implementation dramatically simpler, smaller, more direct, and more elegant.

Rethink how to structure / implement the code to meaningfully improve code quality without impacting behavior. Work to improve abstractions, modularity, reduce Spaghetti code, improve succinctness and legibility. Be ambitious, if there is a clear path to improving the implementation that involves restructuring some of the codebase, go for it. Be extremely thorough and rigorous. Measure twice, cut once.

Be ambitious about structural simplification.
- Do not stop at "this could be a bit cleaner."
- Look for opportunities to reframe the change so that whole branches, helpers, modes, conditionals, or layers disappear entirely.
- Prefer the solution that makes the code feel inevitable in hindsight.
- Assume there is often a "code judo" move available: a re-organization that uses the existing architecture more effectively and makes the change dramatically simpler and more elegant.
- If you see a path to delete complexity rather than rearrange it, push hard for that path.

Bias toward cleaning the design, not just accepting working code.
- If behavior can stay the same while the structure becomes meaningfully cleaner, push for the cleaner version.
- Do not rubber-stamp "it works" implementations that leave the codebase messier.
- Strongly prefer simplifications that remove moving pieces altogether over refactors that merely spread the same complexity around.

Pass this stance to every sub-agent.

## Inputs for `multi-agent-review`

### Rubric source

Read `%USERPROFILE%\.codex\AGENTS.md`, identifies every guideline under the headers whose title contains `Guidelines`.

What counts as one guideline
- Take each `Guidelines` header as a group. Its direct child headings (whatever level they are, one level below the group) are the guideline units.
- Each unit includes everything nested under it: deeper headings, bullets, code blocks.
- Default: one unit = one sub agent. Do NOT split a unit by its subheadings.
- Each sub agent gets the full text of its guideline, including all nested content and have it check every bullet.

When to split
- Split a unit only if it is too big to review as one or its subheadings cover clearly independent concerns.
- If split, each direct child heading becomes its own guideline. Apply the same size test recursively to each child. The parent's own content (bullets directly under the parent header, before any child heading) stays under the parent as its own guideline, labeled with the parent's path.

Labeling
- Label each guideline with its path, e.g. `General > Formatting` or `Unity > Addressables > Core principles`. Same name under different groups = separate guidelines.

### Subject

The code, diff, module, or system the user points at.

### Model

GPT-6 Luna Max as default.

### Severity definitions

- 🔴 **Critical**: Will cause real bugs, data inconsistency, or makes the system unmaintainable at scale
- 🟡 **Significant**: Slows development, creates tech debt, makes testing hard
- 🟢 **Minor**: Worth fixing, but won't hurt you until the codebase grows

### Terminology

In the engine's templates, "criterion" means "guideline", "subject" means "code", and the report title is "Architecture Review: [file/module name or system name]".