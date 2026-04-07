I need to create an agent skill.md to design code architecture for a game feature in Unity: focus on Extensible, Modularity, Decoupling, Single Source of Truth (DRY).

Here are some things I want to know about the architecture:

Extension Points: Explicitly call out where and how a developer adds new variants without modifying existing code (Open/Closed Principle).
    Mark each module accordingly. If everything is "open," nothing is — be selective.

Events: List every event the feature fires or listens to. Use a table.

System Map: A plain-text dependency diagram showing every system involved and the direction of their dependencies.

Decomposition: Break the feature into layers or modules. Each module must have:
    - A single, named responsibility
    - Defined inputs and outputs (types/interfaces, not implementation)
    - A clear owner (who calls it, who it calls)
    Rule: If you can't name the responsibility in 5 words, the module is too large.

Trade-off Commentary: For each major decision, briefly explain:
    - Why this way (what principle it serves)
    - What it costs (complexity, indirection, learning curve)
    - When to revisit (what signal would change this decision)
    Do not omit this phase. Architecture without trade-off reasoning is decoration.

Contracts (Interfaces)
Every cross-system boundary must be an interface. Show all interfaces the feature exposes or consumes.
```csharp
public interface ISystemName
{
    ReturnType MethodName(ParamType param);
    ReturnType MethodName2();
    // signatures only — no bodies
}
```
Rules:
One interface per cross-system role
No Unity types (no GameObject, no Transform) in interface signatures — use plain C# or domain types
If a system needs to react to Unity lifecycle, keep that in the concrete class, not the interface

Concrete Systems
For each system, show:
- What interface(s) it implements
- What it depends on (injected via constructor or service locator)
- Its public surface (method signatures only)
- Its Unity entry point if it's a MonoBehaviour
- Show major classes only. No need to show every helper or data class.

SSOT
Explicitly call out any state or logic that is duplicated across systems, or any derived values that are manually kept in sync instead of computed from a single source. If there are none, say "No SSOT violations identified."

What This System Does NOT Own
Explicit boundary list. Every out-of-scope concern should name which system owns it instead.
```
❌ Saves/loads data          → Owned by: SaveSystem
❌ Plays audio               → Owned by: AudioSystem
❌ Spawns VFX                → Owned by: VFXSystem
```

Anti-patterns to Call Out
If you see these in the user's existing code or implied design, flag them explicitly:
- God module — one module does everything
- Prop drilling / data shotgun — same data passed through many layers unnecessarily
- Implicit coupling — modules share mutable state without explicit contract
- Duplicate truth — same value computed or stored in two places with no sync strategy
- Premature abstraction — interfaces created before there are two implementations
- Anemic domain model — all logic in services, data objects are just bags of fields

# Guidelines
Don't implement the detail logic. I need to be able to quickly review the architecture
Don't over-engineer. Don't add abstraction until there are at least two concrete use cases for it. Premature abstraction is harder to remove than duplication.