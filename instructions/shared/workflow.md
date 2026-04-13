# Workflow for Task Execution

When given a task, follow this workflow strictly in order. Do not skip steps or jump ahead:

## 1. Understand the Current State

- Run some *Explore* subagents to gather relevant information about the feature, its context, and any existing systems it may interact with.
- When the task spans multiple independent areas (e.g., frontend + backend, different features, separate repos), launch **2-3 *Explore* subagents in parallel** — one per area — to speed up discovery.
- Use `unity-mcp-orchestrator` skill to gather information about the scene setup, existing prefabs, and any relevant Unity assets.
Some common tools to use from the UnityMCP:
- `find_gameobjects` to locate relevant GameObjects in the scene
- `manage_prefabs`: to inspect existing prefabs and their components
- `manage_scene`: to understand the current scene hierarchy and setup

## 2. Understand the Desired State

This will depend on the specific task, but the general pattern is:

- Use the `askQuestion` tool to ask clarifying questions to resolve any ambiguity about the desired state. Do not assume — ask.
- Present some choices and let user choose.
- Describe the state back from your perspective to confirm your understanding with the user: describe only the importance part first - the part where everything else depends on.
- Then ask if it's correct. User will give feedback on what is wrong, and you will fix it and repeat until it's right

## 3. Break down the task

- Step 1: Break down the task into smaller, manageable chunks that an LLM can handle in a single pass. This will help make the implementation more manageable.
- Step 2: Mark which chunks can run in parallel vs. which block on prior chunks.
- Step 3: Store the breakdown in a structured format to `/memories/session/plan.md` via `memory` tool for reference during implementation.

<plan_style_guide>
```markdown
### Plan: {Title (2-10 words)}

**Steps**
1. {Implementation step-by-step — note dependency ("*depends on N*") or parallelism ("*parallel with step N*") when applicable}
2. {For plans with 5+ steps, group steps into named phases with enough detail to be independently actionable}
```
</plan_style_guide>

## 4. Implement

Step 1: Write code following the plans and architecture you designed, adhering to the coding guidelines.
- Implement each chunk of the breakdown one at a time, starting with the most foundational pieces that other parts depend on.
- Run parallel subagents for independent chunks to speed up implementation when possible.
- Then wait for instructions for the next chunk, and implement it, and so on.
Step 2: Use `unity-mcp-orchestrator` skill to implement any Unity-specific logic, such as modifying scenes, creating prefabs, or setting up components.
Step 3: After implementation, use `unity-mcp-orchestrator` skill to run the existing tests to see if the new changes cause the tests to fail. If they do, fix the issues and repeat until tests pass.