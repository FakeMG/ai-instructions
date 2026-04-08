---
name: lcom4
description: >
  Compute LCOM4 (Lack of Cohesion of Methods, version 4) for a class and identify disconnected
  component groups that indicate splitting opportunities. Trigger this skill whenever a user
  shares code for refactoring, code review, or asks about class cohesion, God classes, single
  responsibility violations, or whether a class should be split. Also trigger when the user
  pastes a class and asks "is this too big?", "does this follow SRP?", or anything about
  restructuring class responsibilities — even if they don't mention LCOM4 by name.
---

# LCOM4 Skill

Computes the LCOM4 metric for a class and identifies disconnected method/field component groups
that are candidates for extraction into separate classes.

---

## What is LCOM4?

LCOM4 is the number of **connected components** in the undirected graph where:
- **Nodes** = methods of the class
- **Edges** = two methods share at least one instance field (direct read or write)

A cohesive class has LCOM4 = 1. Any value > 1 means the class has that many loosely coupled
groups of methods that could be split into separate classes.

---

## Exclusion Rules (apply before building the graph)

Strip the following from analysis — do not include them as nodes:

1. **Constructors** — any method that initializes the object (`__init__`, `constructor`, `ClassName()`, etc.)
2. **Property getters and setters** — methods whose sole purpose is reading or writing a single field
   (heuristic: body is 1–2 lines, accesses exactly one field, no other logic)
3. **Static methods** — they don't operate on instance state

What **stays in**:
- All other instance methods, including private/protected helpers

---

## Handling Methods With No Instance Field Access

A method that remains after exclusions but accesses **zero instance fields** (e.g. a utility
method, a pure computation, a method that only calls other methods without touching fields)
is treated as an **isolated component**. It raises LCOM4 by 1.

Do not silently drop it — flag it explicitly in the output (see Output Format).

---

## Algorithm

### Step 1 — Identify instance fields
Collect all instance-level fields (not locals, not statics). Language-specific hints:
- Python: `self.x` assignments in `__init__` or any method
- Java/C#: fields declared at class level without `static`
- JS/TS: `this.x` assignments, or class fields without `static`

### Step 2 — Apply exclusion rules
Remove constructors, getters/setters, and static methods from the method list.

### Step 3 — Map methods → fields accessed
For each remaining method, collect the set of instance fields it reads or writes.
A method with an empty set after this step is an isolated node.

### Step 4 — Build the undirected graph
- One node per remaining method
- Add an edge between method A and method B if their field sets **intersect** (share ≥ 1 field)

### Step 5 — Find connected components
Use Union-Find or BFS/DFS on the graph. Each component is a group of methods reachable
from each other via shared fields.

### Step 6 — Compute LCOM4
LCOM4 = number of connected components found in Step 5.

---

## Output Format

Always produce this structure:

```
LCOM4: <value>

<one of the three verdicts below>
```

### Verdict A — LCOM4 = 1 (cohesive)
```
LCOM4: 1
No split needed. All methods are connected through shared fields.
```

### Verdict B — LCOM4 > 1 (split recommended)
```
LCOM4: <N>
This class has <N> disconnected components. Consider splitting into <N> classes.

Component 1 — [inferred responsibility label if determinable, else "Unnamed"]
  Methods : methodA, methodB, methodC
  Fields  : field1, field2

Component 2 — [label]
  Methods : methodD, methodE
  Fields  : field3

...

Excluded from analysis:
  Constructors : ClassName(), ...
  Getters/Setters : getName(), setName(), ...
  Static methods : utilHelper(), ...

Isolated methods (no field access — each is its own component):
  methodX — accesses no instance fields; treat as utility candidate
```

Attempt to label each component with a short responsibility name based on the fields and
method names (e.g. "Persistence", "Rendering", "Authentication"). If it's not clear, say
"Unnamed — review manually."

---

## Language-Specific Parsing Notes

Read `/references/parsing-hints.md` for per-language guidance on identifying instance fields
vs locals vs statics, and detecting getters/setters in each language.

---

## Edge Cases

| Situation | Handling |
|---|---|
| Method calls another method in the same class (no direct field access) | Not an edge. LCOM4 is field-sharing only, not call-graph based. |
| Field accessed via `this` explicitly vs implicitly | Treat as the same field. |
| Inherited fields | Include if the subclass method directly accesses them. Exclude if the access is entirely through a super call. |
| Abstract/interface methods with no body | Exclude — no field access possible. |
| Anonymous inner classes / lambdas inside a method | Count field captures as field accesses of the enclosing method. |
| Only 1 method remains after exclusions | LCOM4 = 1 by definition. Note it. |
| 0 methods remain after exclusions | LCOM4 is undefined. Report as N/A with a note that the class has no analysable methods. |
| Two methods share a field only via a shared method call (indirect) | Not an edge. Strict field-sharing only. |
