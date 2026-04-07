---
name: architecturing-game-feature
description: >
  Design extensible, modular, decoupled Unity C# game feature architecture without implementing logic.
  Use this skill whenever a user wants to architect a game system or feature in Unity — combat, inventory,
  quests, AI, progression, UI, save systems, or any other game mechanic. Trigger when the user says things
  like "design the architecture for", "how should I structure", "plan out the system for", "what's the best
  way to organize", or "help me architect" any game feature. Also trigger when a user wants to review how
  systems connect, extend, or depend on each other. Always use this skill before any Unity game system
  implementation begins.
---

# Game Architecture Designer — Unity C#

Produces a **scannable architecture document** for a Unity C# game feature. No method bodies. No implementation logic. The goal is to let the developer review structure, extension points, and system dependencies at a glance before writing a single line of real code.

---

## Core Design Principles (apply to every output)

| Principle | How to enforce it |
|---|---|
| **Extensibility** | New variants added by implementing interfaces or extending abstract bases — never by modifying existing classes |
| **Modularity** | Each system owns one concern. No system bleeds into another's domain |
| **Decoupling** | Systems communicate via events, interfaces, or a service locator — never via direct MonoBehaviour references |
| **Single Source of Truth** | One authoritative owner per data domain. All readers go through that owner |

---

## Output Format

Always produce the architecture doc in this exact order:

### 1. System Map
A plain-text dependency diagram showing every system involved and the direction of their dependencies.

```
[SystemA] ──uses──▶ [ISystemBContract]
                          ▲
                    [SystemB]

[EventBus] ◀──fires── [SystemA]
           ──delivers──▶ [SystemC]
```

Arrow direction = dependency direction. Label every arrow with the relationship type: `uses`, `fires`, `delivers`, `owns`, `reads`.

Flag the owner explicitly with a comment: `// OWNED BY: SystemName`

### 2. Contracts (Interfaces)

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
- One interface per cross-system role
- No Unity types (no `GameObject`, no `Transform`) in interface signatures — use plain C# or domain types
- If a system needs to react to Unity lifecycle, keep that in the concrete class, not the interface

### 3. Concrete Systems

For each system, show:
- What interface(s) it implements
- What it depends on (injected via constructor or service locator)
- Its public surface (method signatures only)
- Its Unity entry point if it's a MonoBehaviour

```csharp
// Implements: ISystemName
// Depends on: IotherSystem, IEventBus
// Owns: FeatureData
public class ConcreteSystem : MonoBehaviour, ISystemName
{
    // --- Public API ---
    public ReturnType MethodName(ParamType param);
    public ReturnType MethodName2();

    // --- Unity Lifecycle (if MonoBehaviour) ---
    private void Awake();
    private void OnDestroy();

    // --- Event Handlers ---
    private void OnSomeEvent(EventType e);
}
```

### 4. Events

List every event the feature fires or listens to. Use a table.

| Event | Fired By | Listened By | Payload |
|---|---|---|---|
| `OnFeatureTriggered` | SystemA | SystemB, SystemC | `FeatureEventData` |

Define event payload structs:

```csharp
public struct FeatureEventData
{
    public int Id;
    public float Value;
}
```

### 5. Extension Points

Explicitly call out where and how a developer adds new variants without modifying existing code (Open/Closed Principle).

For each extension point:
- What to implement/extend
- Where to register it
- What NOT to touch

```
EXTEND: Implement INewVariant
REGISTER: In FeatureRegistry.Register<T>() or via ScriptableObject
DO NOT TOUCH: CoreSystem, existing concrete implementations
```

### 6. SSOT Audit
 
Explicitly call out:
- Any state stored in two places that must be kept in sync manually.
- Any derived value that is recomputed in multiple systems instead of computed once and shared.
- Any config value hardcoded in more than one place.
 
If none exist: **"No SSOT violations identified."**
 
Do not skip this section. Silence implies you checked.

### 7. What This System Does NOT Own

Explicit boundary list. Every out-of-scope concern should name which system owns it instead.

```
❌ Saves/loads data          → Owned by: SaveSystem
❌ Plays audio               → Owned by: AudioSystem
❌ Spawns VFX                → Owned by: VFXSystem
```
### 8. Decomposition

Break the feature into layers or modules. Each module must have:
  - A single, named responsibility
  - Defined inputs and outputs (types/interfaces, not implementation)
  - A clear owner (who calls it, who it calls)

Rule: If you can't name the responsibility in 5 words, the module is too large.

### 9. Trade-off Commentary

For each major decision, briefly explain:
  - Why this way (what principle it serves)
  - What it costs (complexity, indirection, learning curve)
  - When to revisit (what signal would change this decision)

Do not omit this phase. Architecture without trade-off reasoning is decoration.

---

## Decoupling Patterns — Pick the Right Tool

Use this to decide how two systems communicate:

| Scenario | Pattern |
|---|---|
| System A needs a result from System B synchronously | Interface injection (`ISystemB`) |
| System A needs to notify others but doesn't care who listens | EventBus / C# event |
| System needs a global service (e.g. AudioSystem) | Service Locator (`ServiceLocator.Get<IAudio>()`) |
| Data shared across systems | ScriptableObject channel or centralized DataStore with one owner |
| Unity scene objects need to communicate | UnityEvent on ScriptableObject, NOT `FindObjectOfType` |

Never use:
- `FindObjectOfType` — creates hidden coupling
- `GetComponent` across unrelated systems — same problem
- Singleton MonoBehaviours accessed directly — use a service locator interface instead

---

## Worked Example Skeleton

If the user's feature is ambiguous, produce a minimal skeleton using a **placeholder feature** to demonstrate the pattern, then ask for the real feature details.

```
Feature: [Name]
Owner: [SystemName]
Data: [DataClass]
Contracts: [IInterface1, IInterface2]
Events fired: [EventA, EventB]
Extends via: [IExtensionPoint]
Out of scope: [X → SystemY, Z → SystemW]
```

---

## Anti-Patterns to Call Out

If the user's description implies any of these, flag them explicitly in the output:

| Anti-Pattern | Problem | Fix |
|---|---|---|
| Manager class doing everything | God object, not modular | Split by single responsibility |
| Systems referencing each other directly | Tight coupling | Introduce interface or event |
| Data or logic duplicated across systems | Multiple sources of truth | Designate one owner, others read via interface |
| Abstract base class for everything | Inflexible inheritance hierarchy | Prefer interface composition |
| Interfaces created before there are two implementations | Over-engineering, unnecessary complexity | Wait for concrete use cases before creating interfaces |

---

## Output Length Guidance

- **Simple feature (1–2 systems):** Full doc, ~80–120 lines
- **Medium feature (3–5 systems):** Full doc, ~150–250 lines
- **Complex feature (6+ systems):** Produce the System Map and Contracts first. Ask the user which systems to expand before writing all concrete classes.

Always prioritize scanability over completeness. The developer should be able to review the architecture in under 5 minutes.