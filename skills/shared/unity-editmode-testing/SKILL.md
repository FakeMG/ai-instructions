---
name: unity-editmode-testing
description: >
  Best practices and patterns for writing Unity tests using VContainer for dependency injection and hand-written dummy/stub classes for faking dependencies. ALWAYS use this skill when the user is writing any test in a Unity project — [Test], [UnityTest], PlayMode, EditMode, or any C# test class in a Unity codebase. Also trigger for MonoBehaviour testing, VContainer test containers, dummy dependencies, prefab instantiation in tests, or isolating systems under test.
  If the user is working in a Unity project and mentions tests at all, use this skill.
---

# Understand the Desired State (overrides the corresponding step in AGENTS.md or any agent instruction file)

## EditMode Testing Workflow

### Step 1 — Identify what needs testing

Before writing a single line, walk the codebase and identify what's worth testing. Not everything needs a test — focus on things that carry real behavior or runtime state.
1. Which classes should be unit tested?
2. Do you need to extract any MonoBehaviour logic into separate testable classes?
3. What dependencies do those classes have that need to be mocked or injected?
4. Which dependencies need abstracting behind an interface to be mockable?
5. What assembly definitions do those classes live in, and do the test assemblies have access to them?

Using the `askQuestions` tool to ask for confirmation.

Present the findings in this format:

```
# EditMode tests:
1. [ClassName1] - Non-MonoBehaviour pure logic class
- Reason for testing (complex logic, edge cases, known bugs)
- Dependencies to mock
- PublicFunctionName1_Condition_ExpectedResult()
- PublicFunctionName2_Condition_ExpectedResult()

2. [ClassName2] - MonoBehaviour needs extraction to be testable
- Reason for testing (complex logic, edge cases, known bugs)
- Dependencies to mock
- PublicFunctionName1_Condition_ExpectedResult()
- PublicFunctionName2_Condition_ExpectedResult()

More classes as needed...
```

Do not proceed to Step 2 until the user confirms the list of tests to write.

### Step 2 — Write skeleton test classes

Produce empty classes and method stubs — no test bodies yet. Present these to the user for sign-off on naming and coverage before filling anything in.
- Use real C# syntax and Unity patterns
- Full method signatures: correct return types, parameter names with types and units
- Method bodies: empty `{ }` or a single `// TODO` line — no real logic

---

## Examples

### EditMode (non-coroutine) Tests

Use plain `[Test]` for pure logic classes that don't need MonoBehaviour or frame waits.

```csharp
public interface IInventoryRepository { int GetItemCount(string itemId); }

public class PlayerService
{
    private readonly IInventoryRepository _repo;

    // Injected via VContainer
    public PlayerService(IInventoryRepository repo) { _repo = repo; }
    public bool HasEnoughHealthPotions() { return _repo.GetItemCount("health_potion") > 0; }
}

// ✅ Good — tests the public-facing behavior
[Test]
public void HasEnoughHealthPotions_ReturnsTrue_WhenRepoHasItems()
{
    // 1. Setup Mock using NSubstitute
    var itemId = "health_potion";
    var mockRepo = Substitute.For<IInventoryRepository>();
    mockRepo.GetItemCount(itemId).Returns(5);

    // 2. Setup VContainer (Scoped for this test)
    var builder = new ContainerBuilder();
    
    // Register the mock instance
    builder.RegisterInstance(mockRepo);
    
    // Register the service we are testing
    builder.Register<PlayerService>(Lifetime.Singleton);

    // 3. Build the container
    using (var container = builder.Build())
    {
        var service = container.Resolve<PlayerService>();

        // 4. Act
        var result = service.HasEnoughHealthPotions();

        // 5. Assert
        Assert.IsTrue(result);
        mockRepo.Received(1).GetItemCount(itemId);
    }
}
```

---

## General Testing Guidelines

- Keep each test focused on 1 behavior; reset state between tests via `[TearDown]`
- Follow the Arrange, Act, Assert structure/
- Cover all 5 test categories for each system: happy path, edge cases, failure cases, integration points, regression guards
- Only test public methods — they represent the class's contract and are what consumers depend on
- Avoid Logic in Tests: If your test contains if statements or complex loops, you probably need a test for your test. Keep them dead simple.
- DO NOT test private or internal methods directly — if a private method feels like it needs its own test, it likely belongs in a separate class
- DO NOT change the value of private or internal fields — if you need it to reach into a class, the design needs to change instead.
- Use dependency injection to provide mocked implementations of dependencies, so tests can isolate the unit under test and assert on interactions.
- Mock external systems (audio, scoring, persistence, time) to verify your code talks to them correctly without relying on their real behavior.

### What to Test

For every system or component, cover these five categories before calling a test suite complete:

- Happy Path: The component does what it advertises with valid, in-range input. This is the baseline — if this fails, nothing else matters.
- Edge Cases: Zero, minimum, maximum, and boundary values.
- Failure Cases: Invalid input, out-of-range values, and missing required state. Assert the **correct exception or error response** — don't just confirm it didn't crash.
If the class is designed to clamp rather than throw, assert the clamped result explicitly instead — the point is to nail down the contract, not leave it ambiguous.
- Integration Points — Verify via Mocks: External dependencies (audio, scoring, persistence, time) must be mocked out so the unit under test is isolated. Use mocking frameworks to assert that the correct calls were made with the correct values. Don't test the dependency itself, test that your code interacts with it as expected.
- Regression Guards: When a bug is fixed or a known bad input is described, encode it as a test immediately. Name it clearly so future readers know exactly what broke.
```csharp
// Regression: Enemy awarded points twice if TakeDamage was called in the same frame as OnDisable
[Test]
public void Regression_Enemy_DoesNotAwardPointsTwice_OnSameFrameDeath() { /* ... Test ... */ }
```

## Unity Testing Guidelines + VContainer

- **EditMode tests** are for pure C# logic — plain `[Test]`, no prefabs, no MonoBehaviour. Instantiate the class directly with `new`.
- **PlayMode tests** are for MonoBehaviour components and prefab lifecycle.
- Always load the prefab via Addressable AssetReferences stored in a Resources-based `TestAssetConfig` ScriptableObject.
- Instantiate it through a **VContainer `ContainerBuilder`**, never with `new` or bare `Object.Instantiate`. This ensures:
    - `Awake` / `Start` lifecycle methods run correctly
    - Serialized fields are wired up
    - All injected dependencies are provided (either real or mocked)
- Spawn prefabs via `RegisterComponentInNewPrefab` in a local `ContainerBuilder` using VContainer.
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

## Technology

- VContainer: For dependency injection in tests.
- NSubstitute: For creating mocks and stubs of dependencies.

---

## Project Setup Checklist

Before writing tests, confirm:
1. `VContainer` package is installed (via Package Manager or `Packages/manifest.json`)
2. Test assemblies have a `GUID` reference to `VContainer` (or `VContainer.Tests`)
3. `NSubstitute` package is installed and referenced in test `.asmdef` files