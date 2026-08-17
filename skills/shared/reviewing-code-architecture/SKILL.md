---
name: reviewing-code-architecture
description: >
  This skill is for reviewing the *architecture* of a system, not just the code.
  Only trigger when the user is explicitly requesting this skill. Otherwise, don't use it.
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

- For each coding guideline header, spawn a fresh context sub-agent (default to GPT-5.6 Sol High) to review the code against that guideline.
- All coding guidelines are equally important. Do not skip any. If a guideline does not apply, explicitly state why.
- Each sub-agent should produce a report of violations, inconsistencies, risks, and missing requirements following the format specified below.

## Main Agent Synthesis Requirements

After all sub-agents have completed, the main agent must combine their reports into one comprehensive, lossless review.

The synthesis must satisfy all of the following:

1. Every sub-agent report must be represented.
- Create a section for every guideline/sub-agent, even when it found no issues.
- Never omit a report because its findings appear minor, repetitive, low severity, or less important than findings from another guideline.

2. Every individual finding must survive synthesis.
- Include every distinct violation, inconsistency, risk, and missing requirement reported by every sub-agent.
- Do not summarize several findings into a broader finding if doing so removes specific details.
- Do not report only the "most important," "highest severity," "top," or "actionable" findings.
- Severity may affect ordering, but must never affect inclusion.

3. Explicitly account for zero-finding and non-applicable reviews.
- If a sub-agent reports no issues, write: No issues found for this guideline.
- If a guideline does not apply, include the sub-agent's explanation of why it does not apply.

4. Deduplication must not cause information loss.
- If multiple sub-agents identify the same underlying issue, the main agent may consolidate it only if it preserves:
  - every guideline that identified it,
  - every affected location,
  - every distinct concern or consequence,
  - and every unique remediation requirement.
- When uncertain whether two findings are truly duplicates, keep them separate.

5. Perform a coverage check before producing the final answer.
- Compare the complete list of guideline headers against the completed sub-agent reports.
- Verify that every guideline has a corresponding synthesis section.
- Compare each sub-agent's findings against the synthesized findings and verify that every finding is included.
- If anything is missing, add it before returning the review.

## Required Final Review Structure

For each guideline, include:

```
Guideline: <guideline header>
Applicability: Applicable / Not applicable
Sub-agent result: Issues found / No issues found
```

Then include every finding from that sub-agent, preserving enough detail to identify:
- Finding type
- Severity, if provided
- File and location
- Relevant code or behavior
- Violated or missing requirement
- Explanation/risk
- Recommended remediation

If there are no findings, explicitly state: `No issues found for this guideline.`
If the guideline is not applicable, explicitly state: `Not applicable: <reason from the sub-agent>`

---

## How to Conduct the Review (Send this to the sub-agent)

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

```
# Architecture Review: [file/module name or system name]

## Summary
One short paragraph: what the code is doing overall and your overall assessment. Be honest — if it's
a mess, say so. If it's mostly sound with a few rough edges, say that instead.

## Findings

### Coding Guideline Name 1 (e.g., "Extensible", "Simplicity", etc.)

#### 🔴 [Finding Title]
**Location**: [file name, line numbers if relevant]
**Problem**: What's wrong, specifically.
**Impact**: What will go wrong because of this.
**Fix**: Concrete recommendation. Show a code sketch if it would make the fix clearer.

[Repeat for each guideline, in severity order]

### Coding Guideline Name N

## Recommended Priority Order
Ordered list of what to fix first, given likely impact vs. effort.
```