---
name: multi-agent-review
description: >
  Orchestration engine for parallel, per-criterion reviews with lossless synthesis.
  Do not trigger directly. Only use when another skill instructs you to follow it.
---

# Multi-Agent Review Engine

Use this skill to run an unusually strict, rigorous review of any subject (code, a design doc, a contract, a deck, etc.) by splitting the review into independent criteria, reviewing each one with its own sub-agent, and combining the results into a single lossless report.

Be extremely thorough and rigorous. Measure twice, cut once.

## Inputs Required From the Calling Skill

The calling skill must provide all of the following:

- **Rubric source**: where the criteria come from (file path, section headers)
- **Subject**: what is being reviewed
- **Severity definitions**: what Critical / Significant / Minor mean in this domain
- **Stance** (optional): the domain's version of "be ambitious"
- **Model** (optional): default model for sub-agents

If any required input is missing, ask the user before spawning any sub-agents.

## Core Review Dimensions

Read the rubric source and identify every criterion in it.

- All criteria are equally important. Do not skip any. If a criterion does not apply, explicitly state why.
- For each individual criterion, spawn exactly one sub-agent with a fresh, independent context, using the calling skill's model as default.
- Name each sub-agent after the criterion it reviews, e.g. Extensible, Simplicity, etc.
- Run all criterion-review sub-agents in parallel.
- Because sub-agents start with a fresh context, give each one: its criterion (with the full text from the rubric), the subject, the context questions, the severity definitions, the stance (if any), and the instructions under "How to Conduct the Review" below.
- Each sub-agent should produce a report of violations, inconsistencies, risks, and missing requirements following the format specified below.
- After spawning all required sub-agents, the main agent must wait until every sub-agent has completed. While waiting, the main agent must remain idle, do nothing.
- Only after every sub-agent has completed may the main agent resume work and combine all sub-agent reports into a single comprehensive review.

## Main Agent Synthesis Requirements

After all sub-agents have completed, the main agent must combine their reports into one comprehensive, lossless review.

The synthesis must satisfy all of the following:

1. Every sub-agent report must be represented.
- Create a section for every criterion/sub-agent, even when it found no issues.
- Never omit a report because its findings appear minor, repetitive, low severity, or less important than findings from another criterion.

2. Every individual finding must survive synthesis.
- Include every distinct violation, inconsistency, risk, and missing requirement reported by every sub-agent.
- Do not summarize several findings into a broader finding if doing so removes specific details.
- Do not report only the "most important," "highest severity," "top," or "actionable" findings.
- Severity may affect ordering, but must never affect inclusion.

3. Explicitly account for zero-finding and non-applicable reviews.
- If a sub-agent reports no issues, write: No issues found for this criterion.
- If a criterion does not apply, include the sub-agent's explanation of why it does not apply.

4. Deduplication must not cause information loss.
- If multiple sub-agents identify the same underlying issue, the main agent may consolidate it only if it preserves:
  - every criterion that identified it,
  - every affected location,
  - every distinct concern or consequence,
  - and every unique remediation requirement.
- When uncertain whether two findings are truly duplicates, keep them separate.

5. Perform a coverage check before producing the final answer.
- Compare the complete list of criterion headers against the completed sub-agent reports.
- Verify that every criterion has a corresponding synthesis section.
- Compare each sub-agent's findings against the synthesized findings and verify that every finding is included.
- If anything is missing, add it before returning the review.

## Required Final Review Structure

For each criterion, include:

```
Criterion: <criterion header>
Applicability: Applicable / Not applicable
Sub-agent result: Issues found / No issues found
```

Then include every finding from that sub-agent, preserving enough detail to identify:
- Finding type
- Severity, if provided
- Location
- Relevant content or behavior
- Violated or missing requirement
- Explanation/risk
- Recommended remediation

If there are no findings, explicitly state: `No issues found for this criterion.`
If the criterion is not applicable, explicitly state: `Not applicable: <reason from the sub-agent>`

Order criteria sections as they appear in the rubric. Within each section, order findings by severity. Severity affects ordering, never inclusion.

---

## How to Conduct the Review (Send this to the sub-agent)

### Step 1: Understand the context
Gather relevant information about the subject, its context, and any existing systems or documents it may interact with.

### Step 2: Read the subject fully before commenting
Don't start commenting on line 5 before reading the whole file or document. Structural problems often only become
apparent once you see the full picture.

### Step 3: Prioritize findings
Not everything is equally bad. Sort findings using the severity definitions provided by the calling skill:
- 🔴 **Critical**
- 🟡 **Significant**
- 🟢 **Minor**

Within your own criterion, do not flood the review with low-value nits if there are larger structural issues. Prefer a smaller number of high-conviction comments over a long list of cosmetic notes. (This prioritization applies only to how you write your report. The main agent's synthesis must still include every finding you report.)

### Step 4: Structure the output

Use this format:

```
# Review: [file/module name or subject name]

## Summary
One short paragraph: what the subject is doing overall and your overall assessment. Be honest — if it's
a mess, say so. If it's mostly sound with a few rough edges, say that instead.

## Findings

### Criterion Name (e.g., "Extensible", "Simplicity", etc.)

#### 🔴 [Finding Title]
**Location**: [file name, line numbers or section if relevant]
**Problem**: What's wrong, specifically.
**Impact**: What will go wrong because of this.
**Fix**: Concrete recommendation. Show a sketch if it would make the fix clearer.

[Repeat for each finding, in severity order]

## Recommended Priority Order
Ordered list of what to fix first, given likely impact vs. effort.
```