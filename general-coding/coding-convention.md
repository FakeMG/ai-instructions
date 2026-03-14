# General Coding Guidelines

## Code Quality & Style
- **Comments:** Do NOT explain *what* code does. Use comments only to explain *why* a complex decision was made, to warn of pitfalls, or highlight critical non-obvious details.
- **Self-Documenting:** Use clear naming conventions instead of comments (e.g., `if (IsDead())` instead of `// Check if dead`).
- **Constants:** Use named constants; avoid magic numbers or strings.
- **Single Source of Truth (SSOT) / DRY:** Ensure every piece of knowledge or logic has a single, unambiguous representation within the system to avoid synchronization errors.
- **Dependency Injection:** Separate Construction from Use. Classes should not resolve their own dependencies; they must be assigned via Inspector, constructor, or method parameters.
- **Properties:** Avoid public fields; use properties with appropriate accessors.
- **Event Handling:** Avoid lambda expressions for handlers. Always pair subscriptions with unsubscriptions to prevent memory leaks.

## Naming Conventions
- **General:** Follow Microsoft C# conventions (PascalCase for classes/methods, camelCase for variables/parameters).
- **Fields:** Prefix private fields with an underscore `_`.
- **Clarity:** Names must clearly convey purpose without ambiguity. Avoid vague names like `Manager` or `Helper`.
- **Units:** Time durations must include the unit (e.g., `timeoutSeconds`, `delayMilliseconds`).
- **Booleans:** Name to imply true/false (e.g., `isVisible`, `hasCompleted`).
- **Constants:** Must be written in ALL_CAPS (e.g., `MAX_RETRY_COUNT`, `DEFAULT_TIMEOUT_SECONDS`).
- **Consistency:** Use consistent terminology throughout the codebase.
- **Event Handler:** When subscribing to events, name the handler based on the action it performs. (e.g., instead of `OnPlayerCaught`, use a name like `PunishPlayerWhenCaught` or `TriggerPunishment`).

## Architecture & OOP
- **Composition over Inheritance:** Structure code by combining small components rather than deep inheritance hierarchies.
- **SOLID Principles:** Strictly adhere to Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, and Dependency Inversion.
- **LCOM4:** Ensure high cohesion. If methods in a class operate on distinct sets of fields, split them into separate classes.
- **Framework Independence:** Frameworks should not dominate your architecture. Don't let the framework's design dictate your domain logic. Your business rules should be written in "plain" code.
- **Humble Object Pattern:** Extract logic into easy-to-test classes (POCOs/Plain classes), leaving the framework-dependent classes (like MonoBehaviours) as "humble" wrappers with minimal logic.

## Methods
- **Size:** Methods must be small, focused on a single task, and at a single level of abstraction.
- **Length:** Avoid trivial one-liners; methods should have meaningful length (min 3 lines).
- **Arguments:** Minimize arguments. Ideal: 0, Good: 1, Acceptable: 2. Avoid 3+. Use return values instead of output arguments.
- **Ordering:** Place methods in the order they are called (caller before callee) to read like a story.
- **Side Effects:** Functions must have no side effects outside their explicit purpose.