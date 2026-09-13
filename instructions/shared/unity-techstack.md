# Technology Stack

Use the following libraries and tools when the feature being implemented requires the capability they provide.
Do not add or use a different library as a substitute for one listed here. If a required library is not present in the project, ask the user to add it.

## UniTask
- Use UniTask for asynchronous operations.
- Never write Unity Coroutines in this project.

## DOTween
- Use DOTween for animations and tweens.

## Addressables
- Use Addressables for assets that require dynamic or addressable loading.
- Do not use Addressables merely because an asset exists in the project.

## Cinemachine
- Use Cinemachine for camera control.

## Animancer
- Use Animancer for playing pre-made animations.

## TextMeshPro
- Use TextMeshPro for text rendering.

## Odin Inspector
- Use Odin Inspector for enhanced editor functionality where appropriate.

## VContainer
- Use VContainer for dependency injection and lifetime management.
- Each system must have its own installer script.
- Keep the installer script inside that system's folder.
- Each installer must organize its registrations by responsibility.
- Persistence registrations must be placed in a dedicated persistence install function.

## Unity Input System
- Use Unity's Input System for player input.
- Whenever code needs to reference or use an input action, it must do so through an InputActionReference.
- Do not find, retrieve, or reference an InputAction directly by action name.

## FakeMGFramework
- Prefer existing FakeMGFramework utilities and systems instead of implementing duplicate functionality.
- Check whether FakeMGFramework already provides the required functionality before creating a new core utility or system.
- Use `FakeMG.Framework.Echo` for project logging.
- Use `DatabaseSO<T>` for catalogs containing one `IdentitySO`-derived type. Example: `ItemDatabaseSO : DatabaseSO<ItemSO>`.
- Derive ScriptableObject definitions from `IdentitySO` when they require a stable, unique ID for catalog lookup or save data.
  - Examples: items, entities, structures, recipes, categories, and equipment.
- Every component implementing `ISaveable` must:
  - Be registered by its system's installer in that installer's persistence install function.
  - Physically exist as a child somewhere under: `Core Managers Variant.prefab → Save Load System Gameplay`
  - Have a stable and unique `SaveId`.
- `ManagersLifetimeScope.Configure` is responsible for calling the persistence install function of each system that contains persistence registrations.