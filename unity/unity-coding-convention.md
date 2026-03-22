# Unity-Specific Development Guidelines

## Lifecycle & MonoBehaviour

**Do:**
- Group Unity lifecycle methods (`Awake`, `Start`, etc.) together at the top of the class, immediately after fields/properties.
  ```csharp
  // ✅ Good — lifecycle methods grouped at the top
  public class Enemy : MonoBehaviour
  {
      [SerializeField] private float _speed;
      private Rigidbody _rigidbody;

      private void Awake()      => _rigidbody = GetComponent<Rigidbody>();
      private void Start()      => ApplyInitialState();
      private void OnEnable()   => SubscribeToEvents();
      private void OnDisable()  => UnsubscribeFromEvents();

      private void ApplyInitialState() { ... }
  }
  ```

**Avoid:**
- Avoid scattering lifecycle methods throughout the class, mixed in with other methods.
  ```csharp
  // ❌ Bad — lifecycle methods buried among helpers
  public class Enemy : MonoBehaviour
  {
      private void ApplyInitialState() { ... }
      private void Awake() => _rigidbody = GetComponent<Rigidbody>();
      private void CalculateDamage() { ... }
      private void Start() => ApplyInitialState();
  }
  ```

---

**Do:**
- Keep `MonoBehaviours` thin — delegate all decision-making and math to a separate POCO.
  ```csharp
  // ✅ Good — MonoBehaviour only bridges Unity and the POCO
  public class EnemyMono : MonoBehaviour
  {
      private EnemyBrain _brain;

      private void Awake() => _brain = new EnemyBrain();
      private void Update() => transform.position += _brain.ComputeMovement(Time.deltaTime);
  }

  public class EnemyBrain   // POCO — no Unity dependency
  {
      public Vector3 ComputeMovement(float deltaTime) { ... }
  }
  ```

**Avoid:**
- Avoid putting complex game logic directly inside a MonoBehaviour.
  ```csharp
  // ❌ Bad — MonoBehaviour doing all the thinking
  public class EnemyMono : MonoBehaviour
  {
      private void Update()
      {
          if (_distanceToPlayer < _detectionRange)
          {
              _currentState = EnemyState.Chasing;
              var dir = (_player.position - transform.position).normalized;
              transform.position += dir * _speed * Time.deltaTime;
          }
      }
  }
  ```

---

**Do:**
- Keep purely mathematical data (e.g., `Vector3`) in the POCO for readability.
  ```csharp
  // ✅ Good — Vector3 is pure math, acceptable in a POCO
  public class ProjectilePath
  {
      public Vector3 ComputeArc(Vector3 origin, Vector3 target, float height) { ... }
  }
  ```

**Avoid:**
- Avoid putting Unity Engine-dependent types (e.g., `Collider`, `Renderer`) in the POCO.
  ```csharp
  // ❌ Bad — POCO now requires the Unity Engine to be running
  public class EnemyBrain
  {
      public Collider DetectionZone;   // Engine type leaking into POCO
      public Renderer BodyRenderer;
  }
  ```

----------------------------------------------------------------------------------

## Performance

**Do:**
- Use `async UniTask` for non-blocking operations.

---

**Do:**
- Always add timeouts and cancellation tokens to asynchronous operations.
  ```csharp
  // ✅ Good — won't hang indefinitely
  var cts = new CancellationTokenSource(TimeSpan.FromSeconds(5));
  await LoadEnemyDataAsync(cts.Token);
  ```

**Avoid:**
- Avoid firing async operations without a cancellation token or timeout.
  ```csharp
  // ❌ Bad — hangs forever if the operation never completes
  await LoadEnemyDataAsync();
  ```

---

**Do:**
- Cache references (`GetComponent`, `Find`) in `Awake`/`Start`.
  ```csharp
  // ✅ Good — cached once, reused every frame
  private Rigidbody _rigidbody;
  private void Awake() => _rigidbody = GetComponent<Rigidbody>();
  private void Update() => _rigidbody.AddForce(Vector3.up);
  ```

**Avoid:**
- Avoid using search methods like `Find` or `GetComponent` in `Update`.
  ```csharp
  // ❌ Bad — GetComponent called every frame
  private void Update() => GetComponent<Rigidbody>().AddForce(Vector3.up);
  ```

---

**Do:**
- Use pooling for frequent instantiation/destruction.
  ```csharp
  // ✅ Good — reuses existing objects, no GC pressure
  var bullet = _bulletPool.Get();
  bullet.transform.position = _muzzle.position;
  ```

**Avoid:**
- Avoid instantiating and destroying objects at high frequency.
  ```csharp
  // ❌ Bad — spikes GC every time a bullet is fired or despawned
  Instantiate(_bulletPrefab, _muzzle.position, Quaternion.identity);
  Destroy(bullet, 3f);
  ```

---

**Do:**
- Use events or UniTask instead of `Update()` where possible.
  ```csharp
  // ✅ Good — reacts only when something actually changes
  private void OnEnable()  => _healthSystem.OnDied += TriggerDeathSequence;
  private void OnDisable() => _healthSystem.OnDied -= TriggerDeathSequence;
  ```

**Avoid:**
- Avoid polling state every frame in `Update()` when an event-driven approach is viable.
  ```csharp
  // ❌ Bad — checks death condition 60 times per second unnecessarily
  private void Update()
  {
      if (_healthSystem.IsDead) TriggerDeathSequence();
  }
  ```

----------------------------------------------------------------------------------

## Exception Handling

**Do:**
- Use guard clauses and `TryGetComponent` instead of exceptions for expected runtime conditions.
  ```csharp
  // ✅ Good — no allocation, no stack unwind, reads cleanly
  private void Update()
  {
      if (!TryFindTarget(out var target)) return;
      MoveToward(target);
  }
  ```

**Avoid:**
- Avoid throwing exceptions inside runtime loops (`Update`, `FixedUpdate`, coroutines) — they are expensive, allocate heap memory, and can trigger GC spikes.
  ```csharp
  // ❌ Bad — exception thrown every frame if target is missing
  private void Update()
  {
      var target = FindTarget(); // throws if none found
      MoveToward(target);
  }
  ```

---

**Do:**
- Use return values or result patterns for expected or recoverable outcomes.
  ```csharp
  // ✅ Good — caller decides what to do when none exists
  public bool TryFindNearestEnemy(out Enemy enemy)
  {
      enemy = _enemies.Count > 0 ? _enemies[0] : null;
      return enemy != null;
  }
  ```

**Avoid:**
- Avoid using exceptions for expected or recoverable outcomes — they are not control flow.
  ```csharp
  // ❌ Bad — exception used as control flow for a normal case
  public Enemy FindNearestEnemy()
  {
      if (_enemies.Count == 0) throw new InvalidOperationException("No enemies found.");
      return _enemies[0];
  }
  ```

----------------------------------------------------------------------------------

## Asset Management (Addressables)

**Do:**
- Load assets using `Addressables.LoadAssetAsync<T>()`.
  ```csharp
  // ✅ Good
  var handle = Addressables.LoadAssetAsync<GameObject>("EnemyPrefab");
  await handle.Task;
  var prefab = handle.Result;
  ```

---

**Do:**
- Track the `AsyncOperationHandle` and release it when done to prevent leaks.
  ```csharp
  // ✅ Good — handle is stored and released on cleanup
  private AsyncOperationHandle<GameObject> _enemyHandle;

  private async UniTask LoadAsync()
  {
      _enemyHandle = Addressables.LoadAssetAsync<GameObject>("EnemyPrefab");
      await _enemyHandle.Task;
  }

  private void OnDestroy() => Addressables.Release(_enemyHandle);
  ```

----------------------------------------------------------------------------------

## Architecture Patterns

**Do:**
- Suffix ScriptableObject names with `SO`.
  ```csharp
  // ✅ Good — immediately identifiable as a ScriptableObject
  [CreateAssetMenu]
  public class EnemyDataSO : ScriptableObject { ... }
  ```

**Avoid:**
- Avoid naming ScriptableObjects without the `SO` suffix — they become indistinguishable from regular data classes.
  ```csharp
  // ❌ Bad — looks like a plain C# class
  public class EnemyData : ScriptableObject { ... }
  ```

---

**Do:**
- Use C# Events for inter-system communication.
  ```csharp
  // ✅ Good — fast, type-safe, no reflection
  public class HealthSystem
  {
      public event Action OnDied;
      private void Die() => OnDied?.Invoke();
  }
  ```

**Avoid:**
- Avoid using `UnityEvent` — it's slower, uses reflection, and hides wiring in the Inspector.
  ```csharp
  // ❌ Bad — overhead and control flow hidden in the Inspector
  public class HealthSystem : MonoBehaviour
  {
      public UnityEvent OnDied;
      private void Die() => OnDied.Invoke();
  }
  ```

---

**Do:**
- Separate event subscription logic from core business logic into a dedicated `Subscriber` MonoBehaviour.
  ```csharp
  // ✅ Good — wiring is isolated; both systems remain independently reusable
  public class EnemyDeathSubscriber : MonoBehaviour
  {
      [SerializeField] private HealthSystem _healthSystem;
      [SerializeField] private ScoreSystem _scoreSystem;
      [SerializeField] private SpawnSystem _spawnSystem;

      private void OnEnable()
      {
          _healthSystem.OnDied += _scoreSystem.AwardPointsWhenEnemyDied;
          _healthSystem.OnDied += _spawnSystem.RespawnEnemyWhenDied;
      }

      private void OnDisable()
      {
          _healthSystem.OnDied -= _scoreSystem.AwardPointsWhenEnemyDied;
          _healthSystem.OnDied -= _spawnSystem.RespawnEnemyWhenDied;
      }
  }
  ```

**Avoid:**
- Avoid mixing event subscription wiring directly into business logic classes, coupling them together.
  ```csharp
  // ❌ Bad — HealthSystem now knows about ScoreSystem and SpawnSystem
  public class HealthSystem : MonoBehaviour
  {
      [SerializeField] private ScoreSystem _scoreSystem;
      [SerializeField] private SpawnSystem _spawnSystem;

      private void OnEnable()
      {
          OnDied += _scoreSystem.AwardPointsWhenEnemyDied;
          OnDied += _spawnSystem.RespawnEnemyWhenDied;
      }
  }
  ```

---

**Do:**
- Route all cross-system communication through events, keeping each system unaware of others.
  ```csharp
  // ✅ Good — EnemyAI knows nothing about who is listening
  public class EnemyAI : MonoBehaviour
  {
      public event Action OnDied;
      private void Die() => OnDied?.Invoke();
  }
  ```

**Avoid:**
- Avoid creating direct references between systems — it creates tight coupling that makes each system impossible to reuse independently.
  ```csharp
  // ❌ Bad — EnemyAI is coupled to three unrelated systems
  public class EnemyAI : MonoBehaviour
  {
      private SoundSystem _soundSystem;
      private UISystem _uiSystem;
      private QuestSystem _questSystem;

      private void Die()
      {
          _soundSystem.PlayDeathSound();
          _uiSystem.ShowKillFeed();
          _questSystem.NotifyEnemyKilled();
      }
  }
  ```