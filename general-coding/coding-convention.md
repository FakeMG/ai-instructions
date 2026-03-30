# General Coding Guidelines

## Modular and Decoupled

**Do:**
- Separate Construction from Use — assign dependencies via Inspector, constructor, or method parameters.
  ```csharp
  // ✅ Good — constructor injection
  public class EnemyAI
  {
      private readonly IPathfinder _pathfinder;
      public EnemyAI(IPathfinder pathfinder) => _pathfinder = pathfinder;
  }
  ```

**Avoid:**
- Avoid letting classes resolve their own dependencies.
  ```csharp
  // ❌ Bad — class creating its own dependency
  public class EnemyAI
  {
      private readonly Pathfinder _pathfinder = new Pathfinder();
  }
  ```

---

**Do:**
- Give each class only one reason to change. Split classes with multiple responsibilities.
  ```csharp
  // ✅ Good — one class per responsibility
  public class PlayerStatsCalculator { ... }
  public class PlayerStatsDisplay { ... }
  ```

**Avoid:**
- Avoid mixing unrelated responsibilities into a single class because it's convenient.
  ```csharp
  // ❌ Bad — too many responsibilities in one class
  public class PlayerStatsManager
  {
      public void Calculate() { ... }
      public void Display() { ... }
      public void SaveToFile() { ... }
  }
  ```

---

**Do:**
- Ensure high cohesion (LCOM4). If methods operate on distinct sets of fields, split them into separate classes.
  ```csharp
  // ✅ Good — each class operates on its own set of fields
  public class MovementHandler  { private Vector3 _velocity; ... }
  public class AnimationHandler { private Animator _animator; ... }
  ```

**Avoid:**
- Avoid keeping methods that operate on unrelated data lumped together in one class.
  ```csharp
  // ❌ Bad — methods share a class but touch completely different fields
  public class PlayerController
  {
      private Vector3 _velocity;
      private Animator _animator;
      private AudioSource _audio;

      private void UpdateMovement() { /* only uses _velocity */ }
      private void UpdateAnimation() { /* only uses _animator */ }
      private void UpdateAudio()     { /* only uses _audio */ }
  }
  ```

---

**Do:**
- Depend on abstractions rather than concrete implementations to reduce coupling and increase testability.
  ```csharp
  // ✅ Good — depends on the interface
  public class EnemyAI
  {
      private readonly IWeapon _weapon;
      private void Attack() { _weapon.Hit(); }
  }
  ```

**Avoid:**
- Avoid abstracting things that don't have (or won't likely have) multiple implementations — premature abstraction adds indirection for no gain.

---

**Do:**
- Decouple systems via events or interfaces — no direct references across module boundaries.
  ```csharp
  // ✅ Good — decouple via event
  public class Enemy
  {
      public event Action<int> OnDied;
      void Die() => OnDied?.Invoke(10);
  }
  ```

**Avoid:**
- Avoid referencing concrete systems directly across module boundaries.
  ```csharp
  // ❌ Bad — Enemy is now tightly coupled to ScoreSystem
  public class Enemy
  {
      private ScoreSystem _scoreSystem;
      void Die() => _scoreSystem.AddPoints(10);
  }
  ```

----------------------------------------------------------------------------------

## Single Source of Truth / DRY

**Do:**
- Ensure every piece of knowledge or logic has a single, unambiguous representation within the system.
  ```csharp
  // ✅ Good — one place owns the max health value
  public class PlayerConfig
  {
      public const int MAX_HEALTH = 100;
  }
  // All other classes reference PlayerConfig.MAX_HEALTH
  ```

**Avoid:**
- Avoid hardcoding values that are already defined elsewhere in the codebase.
  ```csharp
  // ❌ Bad — same value scattered across multiple classes
  // In PlayerSpawner:   player.health = 100;
  // In HealthPickup:    player.health = 100;
  // In SaveSystem:      if (data.health > 100) ...
  ```

---

**Do:**
- Extract shared logic into a single method or class that all callers use.
  ```csharp
  // ✅ Good — one shared implementation
  float damage = DamageCalculator.ComputeDamage(baseDamage, critMultiplier);
  ```

**Avoid:**
- Avoid duplicating logic across multiple locations — if you need to change it, you should only change it in one place.
  ```csharp
  // ❌ Bad — same formula copy-pasted in two classes
  float damageA = baseDamage * 1.5f * critMultiplier;   // in MeleeAttack
  float damageB = baseDamage * 1.5f * critMultiplier;   // in RangedAttack
  ```

---

**Do:**
- Consolidate related data into a single structure that owns all of it together.
  ```csharp
  // ✅ Good — one structure owns both name and health
  EnemyDataSO[] enemies; // each SO holds name + health together
  ```

**Avoid:**
- Avoid keeping parallel data structures that must be kept in sync manually.
  ```csharp
  // ❌ Bad — two arrays that must always match index-for-index
  string[] enemyNames  = { "Goblin", "Orc", "Troll" };
  int[]    enemyHealth = {  50,       150,    300    };
  ```

----------------------------------------------------------------------------------

## Extensibility and Scalability

**Do:**
- Structure code by combining small components (composition over inheritance).
  ```csharp
  // ✅ Good — compose behaviors as components
  public class Player : MonoBehaviour
  {
      [SerializeField] private Mover _mover;
      [SerializeField] private Attacker _attacker;
      [SerializeField] private HealthHandler _health;
  }
  ```

**Avoid:**
- Avoid building deep inheritance hierarchies — they become brittle and hard to reason about.
  ```csharp
  // ❌ Bad — fragile inheritance chain
  Animal → Mammal → Creature → LivingThing → GameObject
  ```

---

**Do:**
- Design modules that are open for extension but closed for modification — use interfaces and abstract classes so new functionality requires only a new class.
  ```csharp
  // ✅ Good — adding a new reward = new class, zero changes to existing code
  public interface IRewardStrategy { void GiveReward(Player player); }

  public class CoinReward : IRewardStrategy { ... }
  public class XpReward   : IRewardStrategy { ... }
  public class ItemReward : IRewardStrategy { ... }  // new behavior, no edits needed
  ```

**Avoid:**
- Avoid editing existing `if/else` chains to add new behavior — this violates the Open/Closed Principle and risks breaking existing cases.
  ```csharp
  // ❌ Bad — every new reward type requires editing this method
  void GiveReward(RewardType type)
  {
      if (type == RewardType.Coin) { ... }
      else if (type == RewardType.Xp) { ... }
      else if (type == RewardType.Item) { ... }   // had to edit existing code
  }
  ```

---

**Do:**
- Replace `if/else` or `switch` chains that check type or state with virtual methods or the Strategy pattern.
  ```csharp
  // ✅ Good — polymorphism, no switch needed
  IAbility ability = GetCurrentAbility();
  ability.Execute(target);
  ```

**Avoid:**
- Avoid writing `if (type == X) ... else if (type == Y)` — use polymorphism instead.
  ```csharp
  // ❌ Bad — grows with every new enemy type
  switch (enemy.Type)
  {
      case EnemyType.Goblin: enemy.Speed = 3f;   break;
      case EnemyType.Orc:    enemy.Speed = 1f;   break;
      case EnemyType.Troll:  enemy.Speed = 0.5f; break;
  }
  ```

----------------------------------------------------------------------------------

## Early and Loudly Feedback

**Do:**
- Write and run tests for important logic.
  ```csharp
  // ✅ Good — tests core damage formula which has real consequences
  [Test]
  public void ComputeDamage_WithCrit_ReturnsDoubledValue()
  {
      float result = DamageCalculator.ComputeDamage(base: 10, critMultiplier: 2f);
      Assert.AreEqual(20f, result);
  }
  ```

**Avoid:**
- Avoid writing tests for trivial getters/setters or simple data structures.
  ```csharp
  // ❌ Bad — tests nothing meaningful
  [Test]
  public void Player_GetName_ReturnsName()
  {
      var player = new Player { Name = "Hero" };
      Assert.AreEqual("Hero", player.Name);
  }
  ```

---

**Do:**
- Only test public functions — they represent the contract of the class and are what consumers depend on.
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

**Avoid:**
- Avoid testing private or internal methods directly — if they need testing, they likely belong in a separate class.
- Avoid using reflection or any framework/library API that bypasses the public interface in tests — if you need it to reach into a class, the design needs to change instead.
  ```csharp
  // ❌ Bad — bypasses access modifiers to test implementation details
  var method = typeof(HealthHandler).GetMethod("ClampHealth", BindingFlags.NonPublic | BindingFlags.Instance);
  method.Invoke(handler, new object[] { -10 });
  ```

---

**Do:**
- Inject dependencies into the class under test so behavior can be verified in isolation.
  ```csharp
  // ✅ Good — fake dependency injected, test is fully isolated. You may want to use framework that is already in the project.
  [Test]
  public void Attack_CallsWeaponHit()
  {
      var fakeWeapon = Substitute.For<IWeapon>();
      var attacker = new Attacker(fakeWeapon);
      attacker.Attack(enemy);
      fakeWeapon.Received(1).Hit(enemy);
  }
  ```

**Avoid:**
- Avoid letting the class under test create its own dependencies — this makes tests brittle and couples them to real implementations.
  ```csharp
  // ❌ Bad — Attacker instantiates its own Weapon; test can't control or verify it
  var attacker = new Attacker();  // internally does: _weapon = new Shotgun();
  attacker.Attack(enemy);
  ```

---

**Do:**
- Make failures obvious and easy to diagnose early.
  ```csharp
  // ✅ Good — asserts loudly if a required dependency is missing
  private void GoodExampleFunction()
  {
      if (_config == null) { Debug.LogError($"{nameof(_config)} is null, cannot apply config."); return; }
  }
  ```

**Avoid:**
- Avoid allowing silent failures.
  ```csharp
  // ❌ Bad — missing config causes subtle misbehavior with no indication of why
  private void BadExampleFunction()
  {
      if (_config != null)
          ApplyConfig(_config);
  }
  ```
----------------------------------------------------------------------------------

## Code Quality & Style

**Do:**
- Use comments only to explain *why* a complex decision was made, to warn of pitfalls, or to highlight critical non-obvious details.
- Use clear naming conventions to make code self-documenting.
- Use properties with appropriate accessors.
- Always pair event subscriptions with unsubscriptions.  
  
  ```csharp
  // ✅ Good — explains a non-obvious design decision
  // We delay by one frame here because the Animator state machine
  // hasn't initialized yet at the point Awake is called.
  await UniTask.Yield();
  ```
  ```csharp
  // ✅ Good — reads like plain English
  if (IsDead()) TriggerDeathSequence();
  ```

**Avoid:**
- Avoid using comments to explain *what* code does.
- Avoid using cryptic or abbreviated names that require a comment to explain.
- Avoid using public fields.
- Avoid using lambda expressions for event handlers — they can't be unsubscribed, causing memory leaks.
  
  ```csharp
  // ❌ Bad — comment just restates the code
  // Check if the player is dead
  if (IsDead()) { ... }
  ```

----------------------------------------------------------------------------------

## Naming Conventions
- **General:** Follow Microsoft C# conventions (PascalCase for classes/methods, camelCase for variables/parameters).
- **Fields:** Prefix private fields with an underscore `_`.
- **Clarity:** Names must clearly convey purpose without ambiguity. Avoid vague names like `Manager` or `Helper`.
- **Units:** Time durations must include the unit (e.g., `timeoutSeconds`, `delayMilliseconds`).
- **Booleans:** Name to imply true/false (e.g., `isVisible`, `hasCompleted`).
- **Constants:** Must be written in ALL_CAPS (e.g., `MAX_RETRY_COUNT`, `DEFAULT_TIMEOUT_SECONDS`).
- **Consistency:** Use consistent terminology throughout the codebase.
- **Event Handler:** When subscribing to events, name the handler based on the action it performs. (e.g., instead of `OnPlayerCaught`, use a name like `PunishPlayerWhenCaught` or `TriggerPunishment`).

----------------------------------------------------------------------------------

## Methods

**Do:**
- Keep methods small, focused on a single task, and at a single level of abstraction.
  ```csharp
  // ✅ Good — each method does exactly one thing
  private void HandleDeath()
  {
      PlayDeathAnimation();
      DropLoot();
      NotifySpawner();
  }
  ```

**Avoid:**
- Avoid writing methods that mix multiple levels of abstraction or do several unrelated things.
  ```csharp
  // ❌ Bad — mixes high-level logic with low-level detail
  private void HandleDeath()
  {
      _animator.SetTrigger("Death");
      foreach (var item in _lootTable) Instantiate(item, transform.position, Quaternion.identity);
      _spawner.ActiveEnemies.Remove(this);
  }
  ```

---

**Do:**
- Give methods meaningful length — at least 3 lines so they encapsulate a real concept.
  ```csharp
  // ✅ Good — the method wraps a meaningful operation
  private bool IsTargetInRange(Enemy target)
  {
      float distance = Vector3.Distance(transform.position, target.transform.position);
      return distance <= _attackRangeMeters;
  }
  ```

**Avoid:**
- Avoid writing trivial one-liners that add a layer of indirection without adding clarity.
  ```csharp
  // ❌ Bad — wrapper adds no value
  private float GetSpeed() => _speed;
  ```

---

**Do:**
- Minimize arguments — ideal: 0, good: 1, acceptable: 2.

**Avoid:**
- Avoid using 3+ arguments — it signals the method is doing too much or data should be grouped into a context object.

---

**Do:**
- Use return values instead of output arguments.
  ```csharp
  // ✅ Good — result is returned naturally
  public float ComputeFinalDamage(float baseDamage, float multiplier)
  {
      return baseDamage * multiplier;
  }
  ```

**Avoid:**
- Avoid using `out` or `ref` parameters as a substitute for a return value.
  ```csharp
  // ❌ Bad — out parameter is awkward and easy to misuse
  public void ComputeFinalDamage(float baseDamage, float multiplier, out float result)
  {
      result = baseDamage * multiplier;
  }
  ```

---

**Do:**
- Place methods in the order they are called — caller before callee — so they read like a story.
  ```csharp
  // ✅ Good — top-to-bottom reading follows execution order
  private void StartLevel() { SpawnEnemies(); StartTimer(); }
  private void SpawnEnemies() { ... }
  private void StartTimer() { ... }
  ```

---

**Do:**
- Keep functions free of side effects outside their explicit purpose.
  ```csharp
  // ✅ Good — returns a value, touches nothing else
  public float ComputeScore(int kills, float timeSeconds)
  {
      return kills * BASE_SCORE_PER_KILL / timeSeconds;
  }
  ```

**Avoid:**
- Avoid producing side effects outside a function's explicit purpose.
  ```csharp
  // ❌ Bad — ComputeScore silently modifies UI and saves data
  public float ComputeScore(int kills, float timeSeconds)
  {
      float score = kills * BASE_SCORE_PER_KILL / timeSeconds;
      _scoreLabel.text = score.ToString();   // hidden side effect
      SaveSystem.Save(score);                // hidden side effect
      return score;
  }
  ```