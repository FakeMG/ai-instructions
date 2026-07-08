---
name: unity-testing
description: >
    Activate this skill when you need to do anything related to testing in a Unity project.
---

# General Testing Guidelines

- Keep each test focused on 1 behavior; reset state between tests via `[TearDown]`
- Follow the Arrange, Act, Assert structure.
- Cover all 5 test categories for each system: happy path, edge cases, failure cases, integration points, regression guards.

## What to Test

For every system or component, cover these five categories before calling a test suite complete:

- Happy Path: The component does what it advertises with valid, in-range input. This is the baseline — if this fails, nothing else matters.
- Edge Cases: Zero, minimum, maximum, and boundary values.
- Failure Cases: Invalid input, out-of-range values, and missing required state. Assert the **correct exception or error response** — don't just confirm it didn't crash.
If the class is designed to clamp rather than throw, assert the clamped result explicitly instead — the point is to nail down the contract, not leave it ambiguous.
- Integration Points — Verify via Mocks: External dependencies (audio, scoring, persistence, time) must be mocked out so the unit under test is isolated. Use mocking frameworks to assert that the correct calls were made with the correct values. Don't test the dependency itself, test that your code interacts with it as expected.
- Regression Guards: When a bug is fixed or a known bad input is described, encode it as a test immediately. Name it clearly so future readers know exactly what broke.

## Unit Tests

- Only test public methods — they represent the class's contract and are what consumers depend on.
- DO NOT test private or internal methods directly — if a private method feels like it needs its own test, STOP. It likely belongs in a separate class.
- DO NOT change the value of private or internal fields — if you need it to reach into a class, STOP. The design needs to change instead.
- If the code structure is too hard to test, STOP and notify the user that the design needs to change. Don't try to force a test on 
- Avoid Logic in Tests: If your test contains if statements or complex loops, you probably need a test for your test. Keep them dead simple.
- Use dependency injection to provide mocked implementations of dependencies, so tests can isolate the unit under test and assert on interactions.
- Mock external systems (audio, scoring, persistence, time) to verify your code talks to them correctly without relying on their real behavior.

---

# Unity Testing Guidelines

## EditMode Test Guidelines

- **EditMode tests** are for pure C# logic, unit tests, no prefabs, no MonoBehaviour.
- DO NOT test MonoBehaviour components in EditMode.

## PlayMode Test Guidelines

- **PlayMode tests** are for MonoBehaviour components and prefab lifecycle (Integration tests).
- DO NOT create test-specific assets (prefabs, materials, ScriptableObjects, etc.). You MUST use production assets for testing.
- Always load the prefab via Addressable AssetReferences stored in a Resources-based `TestAssetConfig` ScriptableObject.
- Instantiate it through a **VContainer `ContainerBuilder`**, never with `new` or bare `Object.Instantiate`. This ensures:
    - `Awake` / `Start` lifecycle methods run correctly
    - Serialized fields are wired up
    - All injected dependencies are provided (either real or mocked)
- Avoid sharing container instances across tests. Always build a fresh container per test
- Avoid resolving from the scene-level `LifetimeScope` during a test — it makes the test fragile and order-dependent
- Always clean up instantiated GameObjects to prevent test pollution. VContainer's `Dispose()` destroys GameObjects it instantiated when the container is disposed.:

```csharp
private IObjectResolver _container;

[TearDown]
public void TearDown()
{
    _container?.Dispose(); // destroys all GameObjects instantiated by VContainer
}
```

### Missing Prefab

If the prefab for the component under test does not exist yet:

1. Use the `unity-mcp-orchestrator` skill to extract prefab from scene or create a production prefab containing only the component under test, saved to `Assets/<Feature>/Prefabs/<ComponentName>.prefab`.
2. If the component has dependencies, DO NOT add live implementations to the prefab, inject mocks instead.
3. Load the created prefab using Addressables.
4. If the test is PlayMode and the prefab needs to be marked as an Addressable: attempt to mark it via UnityMCP. If that isn't possible, tell the user which asset to mark.

### Prefab Loading Strategy

To avoid hardcoded strings and maintain type safety, use a Hybrid Loading Strategy: store a small configuration asset in `Resources` that holds `AssetReference` pointers to your real production Addressable prefabs.

1. The Config Script:
```csharp
[CreateAssetMenu(fileName = "TestAssetConfig", menuName = "Game/Testing/TestAssetConfig")]
public class TestAssetConfig : ScriptableObject
{
    public AssetReferenceGameObject enemyPrefab;
    public AssetReferenceGameObject playerPrefab;
}
```
2. Setup: Save this asset at `Assets/Tests/Resources/TestAssetConfig.asset`. Drag production prefabs into the inspector fields.
3. Execution: Use `Resources.Load<TestAssetConfig>("TestAssetConfig")` to find the config, then `LoadAssetAsync()` to load the specific prefab.

---

# Technology

- VContainer: For dependency injection.
- NSubstitute: For creating mocks and stubs of dependencies.