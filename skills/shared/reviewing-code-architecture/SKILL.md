---
name: reviewing-code-architecture
description: >
  Use this skill whenever the user wants architectural feedback on their code, codebase, or system design.
  Trigger on phrases like: "review my code", "check my architecture", "is this good design?", "how's my
  project structured?", "refactor advice", "is this scalable?", "review my repo", "look at my codebase",
  or any time the user shares code files and wants more than a bug fix — they want structural critique.
  Also trigger when users ask about coupling, cohesion, modularity, extensibility, single source of truth,
  separation of concerns, or dependency management. Do NOT trigger for pure bug fixes or narrow "make this
  function work" requests.
---

# Code Architecture Review Skill

Use this skill for an unusually strict review focused on implementation quality, maintainability, abstraction quality, and codebase health.

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

## Core Review Dimensions

Review the code across all these dimensions aggressively. MUST find and call out violations in all of these areas. Do not give a pass on any of them.:

### 1. Single Source of Truth (SSOT)
Duplicated state multiplies bugs.

Look for (not exhaustive):
- **Duplicated state**: the same data stored/derived in multiple places
- **Derived values recomputed**: values that could be derived but are instead cached manually and kept "in sync"
- **Mirrored config**: constants or config values copied across files instead of imported from one place
- **Parallel data structures**: two lists/maps that must stay in sync to represent the same concept
- **Copy-paste logic**: identical or near-identical functions that should be one

When found, name the specific locations and explain exactly what state is duplicated.

---

### 2. Extensibility
Good architecture lets you add features without rewriting existing code.

Look for (not exhaustive):
- **Switch/if-else chains on type**: should usually be polymorphism or a strategy/registry pattern
- **Hard-coded behavior that will obviously vary**: feature flags, rule sets, handler lists that are baked in
- **Closed classes**: classes that would need modification (not extension) to support new behavior
- **Missing plugin points**: areas where a hook, interface, or event would make future changes non-breaking

---

### 3. Modularity
A modular system lets you change or replace one piece without touching others.

Look for (not exhaustive):
- **God objects/modules**: classes or files that do too many unrelated things (lines > 400).
- **Boundary violations**: logic that leaks across module boundaries (e.g., business rules in controllers, DB queries in views)
- **Unclear ownership**: when it's ambiguous which module "owns" a concept
- **Missing abstraction layers**: direct use of low-level primitives where a domain abstraction should exist
- **Over-modularization**: the opposite — trivially thin modules that add indirection for no reason

Call out both under-abstraction AND over-engineering. Neither is good.

---

### 4. Decoupling
Tight coupling creates change-resistance and untestable code.

Look for (not exhaustive):
- **Direct class/module instantiation** inside business logic instead of dependency injection
- **Cross-layer imports**: e.g., UI importing DB logic, or domain layer importing framework code
- **Implicit dependencies**: functions that reach into global state or singletons without declaring them
- **Event-driven violations**: components that call each other directly when they should communicate via events or interfaces
- **Test-hostile design**: code that can't be unit tested without spinning up databases, APIs, or other services

When found, identify the specific import/call chains causing coupling.

---

### 5. Simplicity
Prefer direct, boring, maintainable code over hacky or magical code.

- Treat brittle, ad-hoc, or "magic" behavior as a code-quality problem.
- Be skeptical of generic mechanisms that hide simple data-shape assumptions.
- Flag thin abstractions, identity wrappers, or pass-through helpers that add indirection without buying clarity.
- **Premature extensibility**: interfaces with one implementation, factories with one product — don't count this as a win.
- Code that makes a reader hold many moving pieces in their head to understand. If the code is so clever that it requires a mental stack trace to follow, it's too complex.

---

### 6. Consistency
Inconsistent patterns and styles create cognitive load and confusion.

Look for (not exhaustive):
- **Inconsistent communication patterns**: some components use events, others call directly
- **Inconsistent data management**: some state is in singletons, some in passed parameters, some in static classes
- **Inconsistent abstraction levels**: some functions do one thing, others do multiple things at once
- **Inconsistent naming conventions**: different styles for similar concepts, or the same style used for different concepts
- **Inconsistent file organization**: similar classes organized differently across the codebase

When found, point out the specific inconsistencies and suggest a unified approach.

---

## How to Conduct the Review

### Step 1: Understand the context
Before critiquing, understand:
- What is this system supposed to do?
- What layer of the stack is this (UI, service, data, infra)?
- What language/framework conventions apply?
- Is this a prototype or production code? (affects severity of findings)

Gather relevant information about the system, its context, and any existing systems it may interact with.

### Step 2: Read the code fully before commenting
Don't start commenting on line 5 before reading the whole file. Architectural problems often only become
apparent once you see the full picture.

### Step 3: Prioritize findings
Not everything is equally bad. Sort findings into:
- 🔴 **Critical**: Will cause real bugs, data inconsistency, or makes the system unmaintainable at scale
- 🟡 **Significant**: Slows development, creates tech debt, makes testing hard
- 🟢 **Minor**: Worth fixing, but won't hurt you until the codebase grows

Do not flood the review with low-value nits if there are larger structural issues. Prefer a smaller number of high-conviction comments over a long list of cosmetic notes.

### Step 4: Structure the output

Use this format:

---

## Architecture Review: [file/module name or system name]

### Summary
One short paragraph: what the code is doing overall and your overall assessment. Be honest — if it's
a mess, say so. If it's mostly sound with a few rough edges, say that instead.

### Findings

#### 🔴 [Finding Title] — [Dimension: SSOT / Decoupling / Modularity / Extensibility]
**Location**: [file name, line numbers if relevant]
**Problem**: What's wrong, specifically.
**Impact**: What will go wrong because of this.
**Fix**: Concrete recommendation. Show a code sketch if it would make the fix clearer.

[Repeat for each finding, in severity order]

### What's Working
Call out 2–3 things that are genuinely well-designed. Don't invent praise — if nothing stands out, skip
this section or say so. Fake positives undermine trust in the real critique.

### Recommended Priority Order
Ordered list of what to fix first, given likely impact vs. effort.

---

## When Code Is Shared in Chunks

If the user shares code in multiple messages, hold your full assessment until you've seen everything
they intend to show. Acknowledge receipt and wait. When they signal they're done, then run the full review.

If you can only see part of a system, be explicit about what you *can't* assess due to missing context.
Don't pretend you've reviewed the architecture when you've only seen one file.