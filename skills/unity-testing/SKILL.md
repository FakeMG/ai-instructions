---
name: unity-testing
description: >
  Best practices and patterns for writing Unity tests using VContainer for dependency injection
  and hand-written dummy/stub classes for faking dependencies. ALWAYS use this skill when the
  user is writing any test in a Unity project — [Test], [UnityTest], PlayMode, EditMode, or any
  C# test class in a Unity codebase. Also trigger for MonoBehaviour testing, VContainer test
  containers, dummy dependencies, prefab instantiation in tests, or isolating systems under test.
  If the user is working in a Unity project and mentions tests at all, use this skill.
---

# Unity Testing with VContainer + Hand-Written Dummies

## Core Principle

Always instantiate the prefab under test through a **VContainer `ContainerBuilder`**, never with `new` or bare `Object.Instantiate`. This ensures:
- `Awake` / `Start` lifecycle methods run correctly
- Serialized fields are wired up
- All injected dependencies are provided (either real or faked)

---

## Pattern 1 — Test a Single Component via Prefab

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

**Key points:**
- `RegisterComponentInNewPrefab` instantiates the prefab and hooks it into VContainer
- `.AsSelf()` lets you resolve by concrete type; `.AsImplementedInterfaces()` exposes interfaces
- `yield return null` lets Unity process one frame (important for state changes driven by Update)

---

## Pattern 2 — Inject Hand-Written Dummy Dependencies

Write minimal dummy classes that implement the required interface and record just enough state to assert on. Register them in the container so VContainer injects them into the prefab instead of pulling in live systems.

```csharp
// Defined in the test assembly — no external libraries needed
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
    Assert.Greater(dummyScore.LastAwardedPoints, 0);
}
```

**Key points:**
- Dummy classes live in the test assembly — no third-party mocking library required
- No-op stubs silence dependencies you don't care about (e.g. `DummyAudioService`)
- Spy-style dummies record calls and values for assertions (e.g. `DummyScoreSystem`)
- Register dummies *before* the prefab so VContainer injects them automatically

---

## Pattern 3 — EditMode (non-coroutine) Tests

Use plain `[Test]` for pure logic classes that don't need MonoBehaviour or frame waits.

```csharp
// ✅ Good — tests the public-facing behavior
[Test]
public void TakeDamage_ReducesHealth()
{
    var health = new HealthHandler(maxHealth: 100);
    health.TakeDamage(30);
    Assert.AreEqual(70, health.Current);
}
```

Reserve `[UnityTest]` / `IEnumerator` only when you need frame yields or MonoBehaviour lifecycle.

---

## Do / Avoid Checklist

### ✅ Do
- Spawn prefabs via `RegisterComponentInNewPrefab` in a local `ContainerBuilder`
- Write hand-written dummy classes for dependencies you don't want to test — no-op stubs for things you want to silence, spy dummies that record calls/values for things you want to assert on
- **Only test public methods** — they represent the class's contract and are what consumers depend on
- `yield return null` after state-mutating calls that may be processed in the next frame
- Keep each test focused on **one behavior**; reset state between tests via `[TearDown]`

### ❌ Avoid
- `new HealthSystem()` — MonoBehaviours require a GameObject host; `Awake` never runs
- `Object.Instantiate(prefab)` without a container — live injected dependencies are unresolved or pulled from the scene container, coupling the test to global state
- Resolving from the scene-level `LifetimeScope` during a test — it makes the test fragile and order-dependent
- Sharing container instances across tests — always build a fresh container per test
- **Testing private or internal methods directly** — if a private method feels like it needs its own test, it likely belongs in a separate class
- **Using reflection to bypass access modifiers** — if you need it to reach into a class, the design needs to change instead:
  ```csharp
  // ❌ Bad — bypasses access modifiers to test implementation details
  var method = typeof(HealthHandler).GetMethod("ClampHealth", BindingFlags.NonPublic | BindingFlags.Instance);
  method.Invoke(handler, new object[] { -10 });
  ```
- **Letting the class under test create its own dependencies** — this couples tests to real implementations and makes them impossible to isolate:
  ```csharp
  // ❌ Bad — Attacker instantiates its own Weapon; test can't control or verify it
  var attacker = new Attacker();  // internally does: _weapon = new Shotgun();
  attacker.Attack(enemy);
  ```

---

## TearDown Pattern

Always clean up instantiated GameObjects to prevent test pollution:

```csharp
private IObjectResolver _container;

[TearDown]
public void TearDown()
{
    _container?.Dispose();
}
```

VContainer's `Dispose()` destroys GameObjects it instantiated when the container is disposed.

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
