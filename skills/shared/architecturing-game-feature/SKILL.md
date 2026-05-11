---
name: architecturing-game-feature
description: Design code architecture for a Unity game feature. Use when the user asks to architect, design, or plan the structure of a Unity feature or system. Produces a class breakdown for approval, resolves design tradeoffs one at a time, then generates C# skeletons with empty/one-liner method bodies as the implementation guide.
---

This skill produces a reviewable architecture plan for a Unity feature before any real logic is written.
Build on top of AGENTS.md. Do not repeat its rules — enforce them silently.

---

# Understand the Desired State (overrides the corresponding step in AGENTS.md or any agent instruction file)

## Step 1 — Identify Tradeoffs

Identify every meaningful design decision in the feature.

Resolve them **one at a time** using the `askQuestions` tool. Mark your recommendation for each decision, but let the user choose.

For each decision, present options in this format:

```
**Decision: [what you're deciding]**

**Option A — [name]** (Recommended)
- [tradeoff bullet]
- [tradeoff bullet]
`[Short code snippets showing the main shape]`
 
**Option B — [name]**
- [tradeoff bullet]
- [tradeoff bullet]
`[Short code snippets showing the main shape]`

**Options C, D, E, ...** (as needed)

**Option Custom** (User-defined)

```

Do not proceed to Step 3 until all decisions are resolved.

### Example of a resolved tradeoff:

**Decision: How should PlayerHealthSystem notify other systems of damage?**
 
**Option A — Abstractions-based approach** (Recommended)
- You can add a "Fire Fruit," "Ghost Fruit," or "Exploding Fruit" simply by creating a new script and a new asset in your project folders. You never have to touch the FruitSpawner script again.
- Designer-Friendly: A designer can create different "Level Configurations" by just swapping out which ScriptableObject assets are in the list.

Core Abstraction:
```c-sharp
public abstract class FruitEffectSettings : ScriptableObject
{
    // The spawner calls this without needing to know the logic inside
    public abstract void ApplyEffect(GameObject fruitInstance);
}
```
Concrete Implementation:
```c-sharp
[CreateAssetMenu(menuName = "Fruit Effects/Ice")]
public class IceFruitSettings : FruitEffectSettings
{
    public int count;
    public int minRequiredDrops = 1;
    public int maxRequiredDrops = 3;

    public override void ApplyEffect(GameObject fruitInstance)
    {
        // Add the Ice component and configure it
        var ice = fruitInstance.AddComponent<IceComponent>();
        ice.Setup(Random.Range(minRequiredDrops, maxRequiredDrops));
    }
}
[CreateAssetMenu(menuName = "Fruit Effects/Stacked")]
public class StackedFruitSettings : FruitEffectSettings
{
    public int minStackSize = 2;
    public int maxStackSize = 4;

    public override void ApplyEffect(GameObject fruitInstance)
    {
        // Logic to stack fruits together
    }
}
```
The FruitSpawner:
```c-sharp
public class FruitSpawner : MonoBehaviour
{
    [SerializeField] private GameObject _fruitPrefab;
    
    // You can now drag and drop ANY FruitEffectSettings asset here in the Inspector
    [SerializeField] private List<FruitEffectSettings> _activeEffects;

    public void SpawnFruit()
    {
        GameObject newFruit = Instantiate(_fruitPrefab);

        foreach (var effect in _activeEffects)
        {
            effect.ApplyEffect(newFruit);
        }
    }
}
```

**Option B — Hardcoding specific classes**
- Tight coupling
- Can't spawn a new fruit type without you opening the script and adding more variables.
```c-sharp
public class FruitSpawner : MonoBehaviour
{
    [SerializeField] private GameObject _fruitPrefab;

    // You have to drag and drop specific effect settings here, and you have to add new variables for each new effect type
    [SerializeField] private IceFruitSettings _iceEffect;
    [SerializeField] private StackedFruitSettings _stackedEffect;

    public void SpawnFruit()
    {
        GameObject newFruit = Instantiate(_fruitPrefab);

        if (_iceEffect != null)
        {
            // Add the Ice component and configure it
            var ice = newFruit.AddComponent<IceComponent>();
            ice.Setup(Random.Range(_iceEffect.minRequiredDrops, _iceEffect.maxRequiredDrops));
        }

        if (_stackedEffect != null)
        {
            // Logic to stack fruits together
        }
    }
}
```
 
### Common decisions to check (not exhaustive):
- EventBus vs C# events vs direct injection for communication
- ScriptableObject config vs runtime data class
- MonoBehaviour vs POCO for logic ownership
- Single generic system vs multiple specialized systems
- Where state lives (who owns it, who reads it)

---

## Step 2 — Class Breakdown

Present a class breakdown for all scripts needed to implement the feature.
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

## Step 3 — Continue

After approval, proceed to the next step of the workflow defined in AGENTS.md, CLAUDE.md, or any other agent instruction file.