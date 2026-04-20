---
name: unity-playmode-testing
description: >
  Activate this skill when you need to do anything related to PlayMode tests in a Unity project.
---

# Understand the Desired State (overrides the corresponding step in AGENTS.md or any agent instruction file)

## Identify the behaviors to test and the components involved

1. Identify which behaviors should be tested.
2. Identify what are the main components involved in each behavior.
3. Which prefabs hold those components? Use production prefabs and not test-specific ones.
4. What are other components on those prefabs that might need injected dependencies?
5. What dependencies do those components have that need to be mocked or injected?
6. Which dependencies need abstracting behind an interface to be mockable?
7. What assembly definitions do those classes live in, and do the test assemblies have access to them?

Using the `askQuestions` tool to ask for confirmation.

Present the findings in this format:
```
# PlayMode tests:
1. [Behavior1]
- Reason for testing (complex logic, edge cases, known bugs)
- Main Monobehavior components involved in the behavior:
    ComponentName1
    ComponentName2
- Prefabs holding the components:
    PrefabName1 (path/to/prefab1)
    PrefabName2 (needs extracting from scene or creating via UnityMCP)
- Other components on those prefabs that might need injected dependencies:
    ComponentName3 (dependency: IAudioService)
    ComponentName4 (dependency: IScoreSystem)
- Dependencies to mock, inject
    IAudioService
    IScoreSystem
    AnimationHandler (needs interface extraction)
- Assembly definitions to add to test assembly for access:
    AssemblyName1
    AssemblyName2

2. [Behavior2]
3. [Behavior3]

More behaviors as needed...
```

Do not proceed to implementation until the user confirms the list of behaviors to test.

Create the prefabs if they don't exist yet using the `unity-mcp-orchestrator` skill, and mark them as Addressables.
Assign them to a `TestAssetConfig` ScriptableObject in a `Resources` folder for loading in tests.

---

## Example: Test a Single Component via Prefab (PlayMode)

Avoid hardcoded strings by using a `TestAssetConfig` (ScriptableObject) in a `Resources` folder.

```csharp
[UnityTest]
public IEnumerator Enemy_TakesDamage_DiesCorrectly()
{
    // ── Arrange ──────────────────────────────────────────
    // You can put this setup code in a [UnitySetUp] method if it's shared or if there is only one test.
    // Load config from Resources instantly
    var config = Resources.Load<TestAssetConfig>("TestConfig");
    
    // Load the production prefab via Addressable Reference
    var handle = config.enemyPrefab.LoadAssetAsync();
    yield return handle;

    // Instantiate other dependencies as needed (e.g. Camera, EventSystem) or load them from prefabs too

    var builder = new ContainerBuilder();
    builder.RegisterComponentInNewPrefab(handle.Result, Lifetime.Scoped)
           .AsImplementedInterfaces()
           .AsSelf();

    var container = builder.Build();
    var health = container.Resolve<HealthSystem>();

    // ── Act ─────────────────────────────────────────────

    health.TakeDamage(health.MaxHealth);
    yield return null;

    // ── Assert ──────────────────────────────────────────
    Assert.IsTrue(health.IsDead);

    config.enemyPrefab.ReleaseAsset();
}
```

---

## Missing Prefab — Create One with UnityMCP

If the prefab for the component under test does not exist yet:

1. Use the `unity-mcp-orchestrator` skill to create a minimal prefab containing only the component under test, saved to `Assets/<Feature>/Prefabs/<ComponentName>.prefab`.
2. If the component has dependencies, DO NOT add live implementations to the prefab, inject mocks instead.
3. Load the created prefab using Addressables.
4. If the test is PlayMode and the prefab needs to be marked as an Addressable: attempt to mark it via UnityMCP. If that isn't possible, tell the user which asset to mark and how (`Window > Asset Management > Addressables > Groups`, drag the prefab in).

---

## Prefab Loading Strategy

To avoid hardcoded strings and maintain type safety, use a Hybrid Loading Strategy: store a small configuration asset in `Resources` that holds `AssetReference` pointers to your real production Addressable prefabs.

1. The Config Script:

```csharp
[CreateAssetMenu(fileName = "TestConfig", menuName = "Testing/TestConfig")]
public class TestAssetConfig : ScriptableObject {
    public AssetReferenceGameObject enemyPrefab;
    public AssetReferenceGameObject playerPrefab;
}
```
2. Setup: Save this asset at `Assets/Tests/Resources/TestConfig.asset`. Drag real prefabs into the inspector fields.
3. Execution: Use `Resources.Load<TestAssetConfig>("TestConfig")` to find the config, then `LoadAssetAsync()` to load the specific prefab.


All prefab-based tests are **PlayMode** tests. Load via Addressables before building the container.

**Key points:**
- The Addressable address is the asset path by default unless a custom address has been set
- Release the handle at the end of the test or in `[TearDown]` to avoid memory leaks
- If the prefab isn't marked as an Addressable yet, use UnityMCP to mark it — if that isn't possible, ask the user to do it manually (`Window > Asset Management > Addressables > Groups`, drag the prefab in)


---

## Project Setup Checklist

1. `TestAssetConfig.asset` exists in a `Resources/` folder.
2. Real prefabs under test are marked as Addressables and assigned in `TestAssetConfig`.