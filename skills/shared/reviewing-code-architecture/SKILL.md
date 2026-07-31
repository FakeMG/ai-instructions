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

Before conducting the code review, read and apply all coding guidelines defined in: `%USERPROFILE%\.codex\AGENTS.md`

- For each guideline header, spawn a fresh context sub-agent (default to GPT-5.6 Sol High) to review the code against that guideline.
- All guidelines are equally important. Do not skip any. If a guideline does not apply, explicitly state why.
- Each sub-agent should produce a report of violations, inconsistencies, risks, and missing requirements following the format specified below.
- The main agent should then synthesize these reports into a single comprehensive review.

---

## How to Conduct the Review

### Step 1: Understand the context
Before critiquing, understand:
- What is this system supposed to do?
- What layer of the stack is this (UI, service, data, infra)?
- What language/framework conventions apply?

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

#### 🔴 [Finding Title] — [Dimension: Guideline Header Name]
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