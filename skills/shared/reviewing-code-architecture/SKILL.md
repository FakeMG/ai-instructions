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

You are performing a structured architectural review. Your job is to identify real, concrete problems — not
to catalogue every pattern you recognize. Be direct. Be specific. Don't soften criticism that deserves to
be sharp.

## Core Review Dimensions

Review the code across these four dimensions, in this priority order:

### 1. Single Source of Truth (SSOT)
The most critical dimension. Violations here multiply bugs.

Look for:
- **Duplicated state**: the same data stored/derived in multiple places
- **Derived values recomputed**: values that could be derived but are instead cached manually and kept "in sync"
- **Mirrored config**: constants or config values copied across files instead of imported from one place
- **Parallel data structures**: two lists/maps that must stay in sync to represent the same concept
- **Copy-paste logic**: identical or near-identical functions that should be one

When found, name the specific locations and explain exactly what state is duplicated.

---

### 2. Decoupling
Tight coupling creates change-resistance and untestable code.

Look for:
- **Direct class/module instantiation** inside business logic instead of dependency injection
- **Cross-layer imports**: e.g., UI importing DB logic, or domain layer importing framework code
- **Implicit dependencies**: functions that reach into global state or singletons without declaring them
- **Event-driven violations**: components that call each other directly when they should communicate via events or interfaces
- **Test-hostile design**: code that can't be unit tested without spinning up databases, APIs, or other services

When found, identify the specific import/call chains causing coupling.

---

### 3. Modularity
A modular system lets you change or replace one piece without touching others.

Look for:
- **God objects/modules**: classes or files that do too many unrelated things
- **Boundary violations**: logic that leaks across module boundaries (e.g., business rules in controllers, DB queries in views)
- **Unclear ownership**: when it's ambiguous which module "owns" a concept
- **Missing abstraction layers**: direct use of low-level primitives where a domain abstraction should exist
- **Over-modularization**: the opposite — trivially thin modules that add indirection for no reason

Call out both under-abstraction AND over-engineering. Neither is good.

---

### 4. Extensibility
Good architecture lets you add features without rewriting existing code.

Look for:
- **Switch/if-else chains on type**: should usually be polymorphism or a strategy/registry pattern
- **Hard-coded behavior that will obviously vary**: feature flags, rule sets, handler lists that are baked in
- **Closed classes**: classes that would need modification (not extension) to support new behavior
- **Missing plugin points**: areas where a hook, interface, or event would make future changes non-breaking
- **Premature extensibility**: interfaces with one implementation, factories with one product — don't count this as a win

---

## How to Conduct the Review

### Step 1: Understand the context
Before critiquing, understand:
- What is this system supposed to do?
- What layer of the stack is this (UI, service, data, infra)?
- What language/framework conventions apply?
- Is this a prototype or production code? (affects severity of findings)

Run the *Explore* subagent to gather relevant information about the system, its context, and any existing systems it may interact with.

If the user hasn't said, ask exactly one clarifying question. Don't ask more than one at a time.

### Step 2: Read the code fully before commenting
Don't start commenting on line 5 before reading the whole file. Architectural problems often only become
apparent once you see the full picture.

### Step 3: Prioritize findings
Not everything is equally bad. Sort findings into:
- 🔴 **Critical**: Will cause real bugs, data inconsistency, or makes the system unmaintainable at scale
- 🟡 **Significant**: Slows development, creates tech debt, makes testing hard
- 🟢 **Minor**: Worth fixing, but won't hurt you until the codebase grows

Only escalate to 🔴 if it genuinely warrants it. Don't cry wolf.

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

## Tone and Approach

- Be specific. "This is tightly coupled" is useless without naming *what* is coupled *to what* and *why it matters*.
- Don't hedge excessively. "You might want to consider possibly thinking about..." is noise.
- Don't moralize. Don't say "this is bad practice" without saying *why it's bad in this specific context*.
- Do distinguish between "this violates a principle" and "this will actually cause you a problem."
- If the code is actually good, say so. Don't manufacture issues to seem thorough.
- If you're uncertain about something (e.g., missing context), say so briefly and move on.

## Language/Framework Notes

Adapt your review to the idioms of the language in use:
- **Python**: watch for mutable default args, circular imports, logic buried in `__init__`, missing `__all__`
- **JavaScript/TypeScript**: watch for implicit any, prop drilling instead of context/store, business logic in components
- **Java/C#**: watch for anemic domain models, service classes that are just bags of static methods, over-use of inheritance
- **Go**: watch for missing interfaces, package coupling, error handling omitted
- **General**: always flag global mutable state, regardless of language

## When Code Is Shared in Chunks

If the user shares code in multiple messages, hold your full assessment until you've seen everything
they intend to show. Acknowledge receipt and wait. When they signal they're done, then run the full review.

If you can only see part of a system, be explicit about what you *can't* assess due to missing context.
Don't pretend you've reviewed the architecture when you've only seen one file.