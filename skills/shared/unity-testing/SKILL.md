---
name: unity-testing
description: >
  Best practices for writing Unity tests using VContainer for dependency injection and
  hand-written dummy/stub classes for faking dependencies. ALWAYS use this skill when the
  user is writing any [Test] or [UnityTest] in a Unity project — including PlayMode, EditMode,
  MonoBehaviour testing, VContainer test containers, dummy dependencies, prefab instantiation
  in tests, or isolating systems under test. If the user is in a Unity project and mentions
  tests at all, use this skill.
---

# Unity Testing with VContainer + Hand-Written Dummies

## Core Principle

Always instantiate the prefab under test through a **VContainer `ContainerBuilder`**, never with `new` or bare `Object.Instantiate`. This ensures:
- `Awake` / `Start` lifecycle methods run correctly
- Serialized fields are wired up
- All injected dependencies are provided (either real or faked)

---

## Patterns

### Pattern 1 — Test a Single Component via Prefab
*Use this when your component has no injected dependencies, or when you don't need to assert on them.*

```csharp
[UnityTest]
public IEnumerator Enemy_TakesDamage_DiesCorrectly()
{
    var builder = new ContainerBuilder();
    builder.RegisterComponentInNewPrefab(
        Resources.Load<GameObject>("Prefabs/Enemy"),
        Lifetime.Scoped
    ).AsImplementedInterfaces().AsSelf();

    var container = builder.Build();
    var health = container.Resolve<HealthSystem>();

    health.TakeDamage(health.MaxHealth);
    yield return null;  // allow frame to process

    Assert.IsTrue(health.IsDead);
}
```

### Pattern 2 — Inject Hand-Written Dummy Dependencies
*Use this when you need to silence a dependency (no-op stub) or verify your code called it correctly (spy dummy).*

```csharp
private class DummyAudioService : IAudioService
{
    public void PlayClip(AudioClip clip) { }  // silent no-op
}

private class DummyScoreSystem : IScoreSystem
{
    public int LastAwardedPoints { get; private set; }
    public int AwardCallCount { get; private set; }

    public void AwardPoints(int points)
    {
        LastAwardedPoints = points;
        AwardCallCount++;
    }
}

[UnityTest]
public IEnumerator Enemy_Dies_AwardsPoints()
{
    var dummyAudio = new DummyAudioService();
    var dummyScore = new DummyScoreSystem();

    var builder = new ContainerBuilder();
    builder.RegisterInstance(dummyAudio).As<IAudioService>();
    builder.RegisterInstance(dummyScore).As<IScoreSystem>();
    builder.RegisterComponentInNewPrefab(
        Resources.Load<GameObject>("Prefabs/Enemy"),
        Lifetime.Scoped
    ).AsSelf();

    var container = builder.Build();
    var health = container.Resolve<HealthSystem>();

    health.TakeDamage(999);
    yield return null;

    Assert.AreEqual(1, dummyScore.AwardCallCount);
    Assert.AreEqual(50, dummyScore.LastAwardedPoints); // assert the exact value, not just > 0
}
```

**Key points:**
- Register dummies *before* the prefab so VContainer injects them automatically
- No-op stubs silence dependencies you don't care about
- Spy dummies record calls and values for assertions
- Dummy classes live in the test assembly — no third-party mocking library required
- If there is no interface to implement, create one — testability is a strong signal for missing abstractions

### Pattern 3 — EditMode (non-coroutine) Tests
*Use plain `[Test]` for pure logic classes that don't need MonoBehaviour or frame waits. Reserve `[UnityTest]` / `IEnumerator` only when you need frame yields or MonoBehaviour lifecycle.*

```csharp
[Test]
public void TakeDamage_ReducesHealth()
{
    var health = new HealthHandler(maxHealth: 100);
    health.TakeDamage(30);
    Assert.AreEqual(70, health.Current);
}
```

---

## What to Test — Five Categories

Cover all five for every system before calling it done.

### 1. Happy Path
The component does what it advertises with valid input. If this fails, nothing else matters.

```csharp
[Test]
public void TakeDamage_ReducesHealth_ByExpectedAmount()
{
    var health = new HealthHandler(maxHealth: 100);
    health.TakeDamage(30);
    Assert.AreEqual(70, health.Current);
}
```

### 2. Edge Cases
Zero, minimum, maximum, and boundary values. Unity systems are especially prone to off-by-one errors around `MaxHealth`, zero-damage hits, and single-frame state transitions.

```csharp
[Test]
public void TakeDamage_ZeroDamage_DoesNotChangeHealth()
{
    var health = new HealthHandler(maxHealth: 100);
    health.TakeDamage(0);
    Assert.AreEqual(100, health.Current);
}

[Test]
public void TakeDamage_ExactMaxHealth_Dies()
{
    var health = new HealthHandler(maxHealth: 100);
    health.TakeDamage(100);
    Assert.IsTrue(health.IsDead);
}
```

### 3. Failure Cases
Invalid input, out-of-range values, missing required state. Assert the **correct exception or error response** — don't just confirm it didn't crash. If the class is designed to clamp rather than throw, assert the clamped result explicitly.

```csharp
[Test]
public void TakeDamage_NegativeValue_ThrowsArgumentException()
{
    var health = new HealthHandler(maxHealth: 100);
    Assert.Throws<ArgumentException>(() => health.TakeDamage(-1));
}
```

### 4. Integration Points — Verify via Dummies
Stub out all external dependencies (audio, scoring, persistence, time) and use spy dummies to assert your code talks to them correctly with the right values.

```csharp
[UnityTest]
public IEnumerator Enemy_Dies_NotifiesScoreSystem_WithCorrectPoints()
{
    var dummyScore = new DummyScoreSystem();

    var builder = new ContainerBuilder();
    builder.RegisterInstance(dummyScore).As<IScoreSystem>();
    builder.RegisterInstance(new DummyAudioService()).As<IAudioService>();
    builder.RegisterComponentInNewPrefab(
        Resources.Load<GameObject>("Prefabs/Enemy"),
        Lifetime.Scoped
    ).AsSelf();

    var container = builder.Build();
    var health = container.Resolve<HealthSystem>();

    health.TakeDamage(999);
    yield return null;

    Assert.AreEqual(1, dummyScore.AwardCallCount);
    Assert.AreEqual(50, dummyScore.LastAwardedPoints);
}
```

### 5. Regression Guards
When a bug is fixed, encode it as a test immediately. Name it clearly so future readers know exactly what broke.

```csharp
// Regression: Enemy awarded points twice if TakeDamage was called in the same frame as OnDisable
[UnityTest]
public IEnumerator Regression_Enemy_DoesNotAwardPointsTwice_OnSameFrameDeath()
{
    var dummyScore = new DummyScoreSystem();
    // ... setup ...
    health.TakeDamage(999);
    yield return null;

    Assert.AreEqual(1, dummyScore.AwardCallCount);
}
```

---

## TearDown — Required, Not Optional

**Always dispose the container in `[TearDown]`.** Forgetting this leaks GameObjects into subsequent tests — they will affect physics, trigger `OnTriggerEnter`, fire events, and cause subtle failures that are extremely hard to debug.

```csharp
private IObjectResolver _container;

[TearDown]
public void TearDown()
{
    _container?.Dispose(); // destroys all GameObjects instantiated by VContainer
}
```

Never share a container instance across tests. Always build a fresh container per test.

---

## Do / Avoid Checklist

### ✅ Do
- Spawn prefabs via `RegisterComponentInNewPrefab` in a local `ContainerBuilder`
- Write hand-written dummy classes — no-op stubs to silence, spy dummies to assert on
- **Only test public methods** — they represent the class's contract
- `yield return null` after state-mutating calls processed in the next frame
- Keep each test focused on **one behavior**
- Assert exact values on spy dummies — `AreEqual(50, ...)` not `Greater(0, ...)`
- Always dispose the container in `[TearDown]`
- Cover all five categories: happy path, edge cases, failure cases, integration points, regression guards

### ❌ Avoid
- `new HealthSystem()` — MonoBehaviours require a GameObject host; `Awake` never runs
- `Object.Instantiate(prefab)` without a container — injected dependencies go unresolved
- Resolving from the scene-level `LifetimeScope` — makes tests fragile and order-dependent
- Sharing container instances across tests — always build fresh
- Testing private/internal methods directly — if it feels like it needs its own test, extract it to a new class
- Using reflection to bypass access modifiers:
  ```csharp
  // ❌ Bad
  var method = typeof(HealthHandler).GetMethod("ClampHealth", BindingFlags.NonPublic | BindingFlags.Instance);
  method.Invoke(handler, new object[] { -10 });
  ```
- Letting the class under test create its own dependencies:
  ```csharp
  // ❌ Bad — Attacker instantiates its own Weapon; test can't control or verify it
  var attacker = new Attacker();  // internally does: _weapon = new Shotgun();
  attacker.Attack(enemy);
  ```
- Vague spy assertions — if the enemy should award exactly 50 points, assert `AreEqual(50, ...)`, not `Greater(0, ...)`

---

## Project Setup Checklist

Before writing tests, confirm:
1. `VContainer` package is installed (via Package Manager or `Packages/manifest.json`)
2. Test assemblies have a `GUID` reference to `VContainer` (or `VContainer.Tests`)
3. Dummy classes are defined inside the test assembly (`.asmdef` with `isEditorOnly: true` or under a `Tests/` folder)
4. Prefabs under test are in a `Resources/` folder or an Addressables group accessible at test runtime

---

## Quick Reference

| Goal | Approach |
|---|---|
| Instantiate prefab via container | `builder.RegisterComponentInNewPrefab(prefab, Lifetime.Scoped)` |
| Expose concrete type | `.AsSelf()` |
| Expose interface | `.As<IMyInterface>()` |
| Inject a dummy | `builder.RegisterInstance(dummy).As<IFoo>()` |
| Silent no-op dependency | Implement interface with empty method bodies |
| Spy dummy (record calls) | Implement interface; store args in a field, increment a counter |
| Wait one frame | `yield return null` |
| Wait N seconds | `yield return new WaitForSeconds(n)` |
| Resolve component | `container.Resolve<MyComponent>()` |
| Test category checklist | Happy path → Edge cases → Failure cases → Integration points → Regression guards |