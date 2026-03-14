# Unity-Specific Development Guidelines

## Lifecycle & MonoBehaviour
- **Ordering:** Unity lifecycle methods (`Awake`, `Start`, etc.) MUST be grouped together at the top of the class, immediately after fields/properties.
- **Separation:** `MonoBehaviours` should be thin. They should primarily handle Unity-specific tasks (rendering, input, physical collisions) and delegate all decision-making math to a separate POCO.
- **POCO for Unity**: If the type requires the Unity Engine to be "running" (like a `Collider` or `Renderer`), keep it out of the POCO. If it is purely mathematical data (like `Vector3`), it is acceptable for the sake of code readability and sanity.

## Performance
- **Async:** Use `async UniTask` for non-blocking operations. Avoid `async void` and Coroutines. Always add timeouts and cancellation tokens to asynchronous operations to prevent potential hangs or unresponsive behavior.
- **Caching:** Cache references (`GetComponent`, `Find`) in `Awake`/`Start`. Never use search methods in `Update`.
- **Object Pooling:** Use pooling for frequent instantiation/destruction.
- **Update Loop:** Avoid `Update()` when possible. Use events or UniTask instead.

## Asset Management (Addressables)
- **Loading:** Always use `Addressables.LoadAssetAsync<T>()`.
- **Memory:** Always track the `AsyncOperationHandle` and release it when done to prevent leaks.

## Null Checking
- **Unity Objects:** Use implicit bool conversion (e.g., `if (gameObject)`). DO NOT use `if (gameObject != null)`.
- **Context:** Only check for nulls on objects that might legitimately be null at runtime (dynamic objects). Do not null-check Editor-assigned references.

## Architecture Patterns
- **ScriptableObjects:** Naming MUST use the suffix `SO` (e.g., `EnemyDataSO`).
- **Event:** Use C# Events (not `UnityEvent`) for performance. Avoid direct references between systems.
- **Subscriber Pattern:**
    - Separate event subscription logic from core business logic so that we can reuse the business logic.
    - Create a specific `Subscriber` MonoBehaviour for listening to events.
    - This class handles the One-to-Many mapping (One class's methods → Many events).