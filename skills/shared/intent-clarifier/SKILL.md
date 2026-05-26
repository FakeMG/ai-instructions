---
name: intent-clarifier
description: >
  Use this skill whenever a user's request feels underspecified, ambiguous, or when there's a richer mental model behind what they said. Trigger when: the user wants the agent to "understand them better", asks it to "ask questions", describes wanting to explain something complex, says things like "I have an idea but can't explain it", "help me think this through", "keep asking me questions", or any time a task would benefit from deeply understanding intent before acting. Also trigger proactively when a request has many possible interpretations and picking the wrong one would waste effort. This skill uses iterative questioning rounds, multi-modal description formats (words, images, tests), and a structured output format to build a rich shared understanding before acting.
---

# Intent Clarifier

A protocol for any AI agent to deeply understand what a user has in mind through structured, iterative questioning — before acting or generating a response.

---

## Core Philosophy

People often have a clear picture in their head but struggle to express it fully on the first try. Understanding is a **collaborative process**: ask targeted questions, receive answers, synthesize and reflect back, repeat — until both sides agree the picture is clear.

The goal is to produce a shared **Intent Document** — a structured description of what the user means — that the agent can then act on confidently. The document need to be so detailed that even if the user walked away, another person could pick it up and understand the intent without needing to ask more questions.

---

## The Information Format

All clarification work converges toward a shared **Intent Document** (see Output section for the full template). The structure has two parts:

- **Definition, Visual** — what the thing *looks like*: its properties, boundaries, and components
- **Boundaries & Constraints** — what the thing is not: the limits, "no-go" zones, and hard requirements.
- **Execution** — what *happens*: a step-by-step walkthrough of each distinct interaction or scenario

Every question asked during clarification is ultimately trying to fill in one of these three parts.

---

## The Clarification Process

### Phase 1 — First Pass

Ask **targeted questions** for each part of the document covering:
1. **What** — What is this thing? What does it look like / what are its parts?
2. **Why** — What's the goal or purpose?
3. **How** — How does it work / what happens step by step?
4. **Who / When / Where** — Context that shapes the answer
5. **Edge cases** — What it is *not*, or what happens when things go wrong?

Separate the questions by part of the Intent Document. Present as a numbered list. Keep each question short and concrete.

### Phase 2 — Synthesize and Reflect

After receiving answers, produce a **draft Intent Document** using the format below. Be explicit: "Here's what I understand — is this right?"

- Fill in what is known confidently
- Mark uncertain parts with `[?]`  or "I'm not sure about..."
- Propose a best guess for gaps rather than leaving them blank

### Phase 3 — Test Round

Generate **a few test statements** — short true/false or yes/no claims about the intent — and ask the user to confirm or correct. Example:

> 1. "This applies to mobile users too." ✓ or ✗?
> 2. "Step 2 always follows step 1." ✓ or ✗?
> 3. "Users never need to authenticate for this." ✓ or ✗?

This surfaces hidden assumptions quickly.

### Phase 4 — Iterate

If the user corrects or adds anything, revise the Intent Document and repeat Phase 3 for only the changed parts. Keep iterating until the user confirms it's accurate.

Then repeat the process again and again starting with Phase 1 with any remaining uncertainties or edge cases until the user feels it's fully captured.

**Stop when:** The user confirms the document is correct.
Then proceed with best understanding.

---

## Multi-Modal Hints

Different information types transmit meaning more effectively in different forms. When words alone seem insufficient, prompt the user to try:

- **Analogy**: "Is there something this reminds you of — even loosely?"
- **Example**: "Can you give one concrete example of this in action?"
- **Image/sketch**: "A screenshot, drawing, or diagram would help here."
- **Counter-example**: "What would a *wrong* version of this look like?"
- **Test case**: "What's the first thing you'd check to know it's right or wrong?"

---

## Output: The Intent Document

When the clarification loop ends, produce a clean final version. Always present the document in a markdown code block for easy copying:

```markdown
# [Title]

## Definition, Visuals
[Clear description — properties, components, appearance, and core identity.]

### Name 1
- Description 1
- Description 2
- ...

### Name N
...

## Boundaries & Constraints
- **Scope Limits**: [What this project will NOT attempt to do.]
- **Hard Constraints**: [Fixed requirements like budget, tech stack, or deadlines.]
- **Negative Space**: [Clarify what this is NOT, to avoid "scope creep" or misinterpretation.]

## Execution

### Interaction 1: [Name]
1. [Step]
2. [Step]
3. [Step]

### Interaction 2: [Name]
1. [Step]
2. [Step]

### Interaction N: [Name]
...
```

Then ask: **"Shall I proceed with this understanding?"** — act only after confirmation.

---

## Tone and Pacing

- Ask one **round** of questions at a time (3–5), never a full interrogation at once
- Reflect back what was understood before asking new questions
- If the user seems frustrated: reduce questions, make a best guess, mark it clearly
- If the user wants to skip clarification: respect it, but state key assumptions being made