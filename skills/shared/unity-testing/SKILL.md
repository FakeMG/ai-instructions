---
name: unity-testing
description: >
    Activate this skill when you need to do anything related to testing in a Unity project.
---

# General Testing Guidelines

- Keep each test focused on one behavior; reset state between tests via `[TearDown]`.
- Follow the Arrange, Act, Assert structure.
- Cover all five test categories for each system: happy path, edge cases, failure cases, integration points, and regression guards.
- Avoid fragile tests that break when you change the implementation without changing the behavior. (e.g., hardcoding paths, relying on specific object names, etc.)

## What to Test

For every system or component, cover these five categories before calling a test suite complete:

- Happy Path: The component does what it advertises with valid, in-range input. This is the baseline — if this fails, nothing else matters.
- Edge Cases: Zero, minimum, maximum, and boundary values.
- Failure Cases: Invalid input, out-of-range values, and missing required state. Assert the **correct exception or error response** — don't just confirm that it didn't crash. If the class is designed to clamp rather than throw, assert the clamped result explicitly instead — the point is to nail down the contract, not leave it ambiguous.
- Integration Points (Verify via Mocks): External dependencies (audio, scoring, persistence, time) must be mocked out so the unit under test is isolated. Use mocking frameworks to assert that the correct calls were made with the correct values. Don't test the dependency itself; test that your code interacts with it as expected.
- Regression Guards: When a bug is fixed or a known bad input is described, encode it as a test immediately. Name it clearly so future readers know exactly what broke.

## Unit Tests

- Only test public methods — they represent the class's contract and are what consumers depend on.
- DO NOT test private or internal methods directly — if a private method feels like it needs its own test, STOP. It likely belongs in a separate class.
- DO NOT change the value of private or internal fields — if you need to reach into a class, STOP. The design needs to change instead.
- If the code structure is too hard to test, STOP and notify the user that the design needs to change. Don't try to force a test onto a design that doesn't support it.
- Avoid complex logic in tests: if your test contains complex logic, you probably need a test for your test. Keep them dead simple.
- Use dependency injection to provide mocked implementations of dependencies, so tests can isolate the unit under test and assert on interactions.
- Mock external systems (audio, scoring, persistence, time) to verify that your code talks to them correctly without relying on their real behavior.

---

# Unity Testing Guidelines

## EditMode Tests

- Use EditMode tests when what you're testing doesn't need the game running, meaning no frame loop, physics, or MonoBehaviour lifecycle.

## PlayMode Tests

- Use PlayMode tests when what you're testing depends on Unity's runtime: the game loop, frames, scenes, or the engine actually running.
- The project's integration tests should be under a shared `Tests` folder, not under a specific feature folder.
- Instantiate prefabs through a **VContainer `ContainerBuilder`**, never with `new` or bare `Object.Instantiate`. This ensures that:
    - `Awake` / `Start` lifecycle methods run correctly.
    - Serialized fields are wired up.
    - All injected dependencies are provided (either real or mocked).
- Avoid sharing container instances across tests. Always build a fresh container per test.
- Avoid resolving from the scene-level `LifetimeScope` during a test — it makes the test fragile and order-dependent.
- Always clean up instantiated GameObjects to prevent test pollution. VContainer's `Dispose()` destroys GameObjects it instantiated when the container is disposed.

### Prefabs

- Use different prefab-loading strategies for framework tests and project tests.
- Prefer constructing test objects in code. Create test prefabs only when Unity serialization, lifecycle, hierarchy, or component relationships are part of the behavior being tested.
- Test-only assets must not be referenced by production scenes, prefabs, Resources, or production Addressables assets.
- Keep test prefabs minimal.
- Avoid loading production prefabs, because production prefabs change constantly.

#### Framework Tests

- Framework test prefabs must be Editor-only.
- Store them under `Editor/Resources`.
- Load them with `AssetDatabase` using the prefab GUID, not a hardcoded asset path.
- Do not make framework test prefabs Addressable.

#### Project Tests

- Project test prefabs must be marked as Addressable.
- Store them under feature-specific `Tests` folders and reference them from a Resources-based `TestAssetConfig` ScriptableObject.
- Load them via Addressable `AssetReference`s so they can run in a test Player.
- Integration tests may load production prefabs, which should be loaded through their existing Addressable `AssetReference`. If there is no existing production prefab, extract the prefab from the scene.
- Project test-only prefabs should live in a dedicated `Test Assets` Addressables group.
- Keep `Include in Build` disabled for that group by default.
- A dedicated test build may temporarily enable `Include in Build`.
- Production builds must never require manually disabling the test group.

---

# Technology

- VContainer: For dependency injection.
- NSubstitute: For creating mocks and stubs of dependencies.