---
name: architecturing-game-feature
description: Design code architecture for a Unity game feature. Use when the user asks to architect, design, or plan the structure of a Unity feature or system. Produces a class breakdown for approval, resolves design tradeoffs one at a time, then generates C# skeletons with empty/one-liner method bodies as the implementation guide.
---

This skill produces a reviewable architecture plan for a Unity feature before any real logic is written.
Build on top of AGENTS.md. Do not repeat its rules — enforce them silently.

---

# Understand the Desired State (Override AGENTS.md)

## Step 1 — Identify Tradeoffs

Before producing any class breakdown, identify every meaningful design decision in the feature.

Resolve them **one at a time** using the `askQuestions` tool. Mark your recommendation for each decision, but let the user choose.

For each decision, present options in this format:

```
**Decision: [what you're deciding]**

**Option A — [name]** (Recommended)
- [tradeoff bullet]
- [tradeoff bullet]
`[1–3 line code example showing the shape]`
 
**Option B — [name]**
- [tradeoff bullet]
- [tradeoff bullet]
`[1–3 line code example showing the shape]`

**Options C, D, E, ...** (as needed)

**Option Custom** (User-defined)

```

Do not proceed to Step 3 until all decisions are resolved.
 
### Example of a resolved tradeoff:
```
**Decision: How should PlayerHealthSystem notify other systems of damage?**
 
**Option A — EventBus** (Recommended)
- Zero coupling — subscriber needs no reference to the sender
- Harder to trace; event origin is implicit
`EventBus<PlayerDamagedEvent>.Raise(new PlayerDamagedEvent(damageAmount));`
 
**Option B — C# event on the class**
- Explicit ownership — caller must hold a reference to subscribe
- Easier to trace and debug
`public event Action<float> OnDamageTaken;`
```
 
### Common decisions to check (not exhaustive):
- EventBus vs C# events vs direct injection for communication
- ScriptableObject config vs runtime data class
- MonoBehaviour vs POCO for logic ownership
- Single generic system vs multiple specialized systems
- Where state lives (who owns it, who reads it)

---

## Step 2 — Class Breakdown

Group classes under folder headers. Do not print a full folder tree — just use the header as a separator.

For each class, show:
- **Class name** — one-sentence responsibility
- **Depends on:** (list interfaces or classes it needs injected or referenced)
- **Communicates via:** (events it raises or subscribes to, if any)

**Abstraction rule:** Only propose an interface if there are at least two concrete implementations in this design. A single-implementation interface is banned — use the concrete class directly.

Before presenting, audit the breakdown against AGENTS.md: flag any class that violates single responsibility, any duplicated logic across classes, any tight coupling, and any premature abstraction. Then fix those issues before showing the breakdown to the user.

Store breakdowns in `/memories/session/class_breakdown.md` using `memory` tool.

Wait for explicit user approval before writing any code.
If the user wants changes, revise the breakdown. Update the memory store. Do not skip to code.

Example format:
```
── Systems/Health ──
PlayerHealthSystem
  Responsibility: Tracks and mutates player HP. Raises events on damage and death.
  Depends on: HealthConfigSO
  Communicates via: OnDamageTaken, OnPlayerDied

── Config ──
HealthConfigSO : ScriptableObject
  Responsibility: Data container for max HP, regen rate, invincibility window.
  Depends on: (none)
  Communicates via: (none)

── Subscribers ──
PlayerHealthSubscriber : MonoBehaviour
  Responsibility: Wires PlayerHealthSystem events to UI and audio responses.
  Depends on: PlayerHealthSystem
  Communicates via: (none — subscriber only)
```

---

## Step 3 — Skeleton Code

Generate one C# file per class.

### Rules for skeleton output:
- Use real C# syntax and Unity patterns
- Full method signatures: correct return types, parameter names with types and units
- Method bodies: empty `{ }` or a single `// TODO` line — no real logic
- Properties: auto-properties only `{ get; private set; }`
- Events: declared with correct delegate type, no invocation logic
- Interfaces: full signatures, no bodies
- Comments: every method gets a short inline `//` comment describing what it does — this is the skeleton's purpose and will be deleted in real code. Also add comments for non-obvious architectural decisions or critical constraints.

### Example skeleton output:

```csharp
// ──────────────────────────────────────────
// HealthConfigSO.cs
// ──────────────────────────────────────────
[CreateAssetMenu]
public class HealthConfigSO : ScriptableObject
{
    // No interface — only one implementation exists
    [SerializeField] private float _maxHealth;
    [SerializeField] private float _regenRatePerSecond;
    [SerializeField] private float _invincibilityDurationSeconds;

    public float MaxHealth                    => _maxHealth;
    public float RegenRatePerSecond           => _regenRatePerSecond;
    public float InvincibilityDurationSeconds => _invincibilityDurationSeconds;
}

// ──────────────────────────────────────────
// PlayerHealthSystem.cs  (POCO — no MonoBehaviour)
// ──────────────────────────────────────────
public class PlayerHealthSystem
{
    public event Action<float> OnDamageTaken;  // float = damageAmount
    public event Action        OnPlayerDied;

    public float CurrentHealth { get; private set; }
    public bool  IsAlive       { get; private set; }

    private readonly HealthConfigSO _config;

    public PlayerHealthSystem(HealthConfigSO config) { }  // inject config

    #region Public Methods
    public void ApplyDamage(float damageAmount) { }  // reduce health, trigger invincibility window
    public void ApplyHeal(float healAmount)     { }  // increase health, clamp to max
    public void Reset()                         { }  // restore full health, clear invincibility state
    #endregion

    #region Private Methods
    private bool IsInvincible()  => default;  // true if inside invincibility window
    private void TriggerDeath()  { }          // set IsAlive false, raise OnPlayerDied
    private void ClampHealth()   { }          // keep CurrentHealth within [0, MaxHealth]
    #endregion
}

// ──────────────────────────────────────────
// PlayerHealthSubscriber.cs  (MonoBehaviour — event wiring only)
// ──────────────────────────────────────────
public class PlayerHealthSubscriber : MonoBehaviour
{
    #region Unity Lifecycle
    private void OnEnable()  { }  // subscribe to PlayerHealthSystem events
    private void OnDisable() { }  // unsubscribe to prevent leaks
    #endregion

    private void UpdateHealthBarWhenDamaged(float damageAmount) { }  // forward damage amount to UI
    private void PlayDeathSequenceWhenPlayerDied()              { }  // trigger animator + audio
}
```

---

## Step 4 — Extend

After skeleton is complete, suggest 1–2 natural next steps the user likely hasn't considered.
Keep it to one sentence each. No implementation detail.