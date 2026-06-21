# Workflow for Task Execution

When given a task, follow this workflow strictly in order. Do not skip steps or jump ahead:

## 1. Understand the Current State

- Gather relevant information about the feature, its context, and any existing systems it may interact with.
- For Unity tasks, also use `unity-mcp-orchestrator` skill to gather information about the scene setup, existing prefabs, and any relevant Unity assets.
Some common tools to use from the UnityMCP:
- `find_gameobjects` to locate relevant GameObjects in the scene
- `manage_prefabs`: to inspect existing prefabs and their components
- `manage_scene`: to understand the current scene hierarchy and setup

**Exit condition:** You can describe what currently exists in the relevant areas.

## 2. Understand the Desired State

This will depend on the specific task, but the general pattern is:

- Step 1: Use the `askQuestion` tool to ask clarifying questions to resolve any ambiguity about the desired state. Do not assume — ask.
   - If the user doesn't really know what they want, present some choices and let user choose.
- Step 2: Describe your understanding back to the user — lead with the most critical part (the part everything else depends on).
- Step 3: Ask: *"Is this correct?"*
- Step 4: Incorporate user feedback and repeat from step 2 until the user confirms.

**Exit condition:** User explicitly confirms your description of the desired state is correct.

## 3. Break down the task

- Step 1: Break down the task into smaller, manageable chunks that an LLM can handle in a single pass. This will help make the implementation more manageable.
- Step 2: Mark which chunks can run in parallel vs. which block on prior chunks.
- Step 3: Store the breakdown in a structured format to `/memories/session/plan.md` via `memory` tool for reference during implementation.
- Step 4: Present the breakdown to the user and wait for explicit user approval before proceeding to implementation.

**Exit condition:** User approves the plan.

<plan_style_guide>
```markdown
### Plan: {Title (2-10 words)}

**Steps**
1. {Implementation step-by-step — note dependency ("*depends on N*") or parallelism ("*parallel with step N*") when applicable}
2. {For plans with 5+ steps, group steps into named phases with enough detail to be independently actionable}
```
</plan_style_guide>

## 4. Implement

- Step 1: Write code following the plans and architecture you designed, adhering to the coding guidelines.
  - 1.1. Implement each chunk of the breakdown one at a time, starting with the most foundational pieces that other parts depend on.
  - 1.2. Run parallel subagents for independent chunks (marked in the plan) to speed up implementation when possible.
  - 1.3. Then wait for instructions for the next chunk, and implement it, and so on.
- Step 2: Use `unity-mcp-orchestrator` skill to implement any Unity-specific logic, such as modifying scenes, creating prefabs, or setting up components.
- Step 3: After implementation, use `unity-mcp-orchestrator` skill to run the existing tests to see if the new changes cause the tests to fail. If they do, fix the issues and repeat until tests pass.

**Exit condition:** All chunks implemented, tests pass, user confirms done.

## 5. Validate

Validate the code against the principles above and check if it meets the feature requirements. If it doesn't, revise the code until it does.

## 6. Output

Present the final code, along with a summary of the architecture and design decisions made, audited against the above principles.