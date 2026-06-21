---
name: unity-mcp-orchestrator
description: Orchestrate Unity Editor via MCP (Model Context Protocol) tools and resources. Use when working with Unity projects through MCP for Unity - creating/modifying GameObjects, editing scripts, managing scenes, running tests, or any Unity Editor automation. Provides best practices, tool schemas, and workflow patterns for effective Unity-MCP integration.
---

# Unity-MCP Operator Guide

This skill helps you effectively use the Unity Editor with MCP tools and resources.

## Template Notice

Examples in `references/workflows.md` and `references/tools-reference.md` are reusable templates. They may be inaccurate across Unity versions, package setups (UGUI/TMP/Input System), and project-specific conventions. Please check console, compilation errors, or use screenshot after implementation.

Before applying a template:
- Validate targets/components first via resources and `find_gameobjects`.
- Treat names, enum values, and property payloads as placeholders to adapt.

## Quick Start: Resource-First Workflow

**Always read relevant resources before using tools.** This prevents errors and provides the necessary context.

```text
1. Check editor state     → mcpforunity://editor/state
2. Understand the scene   → mcpforunity://scene/gameobject-api
3. Find what you need     → find_gameobjects or resources
4. Take action            → tools for scene/object/component operations
5. For scripts            → manually create or edit .cs files directly
6. Refresh Unity only when needed → refresh_unity
7. Wait for compilation   → mcpforunity://editor/state until is_compiling == false
8. Verify results         → read_console, manage_camera(action="screenshot"), resources
```

## Critical Best Practices

### 1. Use `refresh_unity` Conservatively

`refresh_unity` is very slow because it can trigger Unity asset import, script compilation, and domain reload work. Do not call it after every small editor operation. Prefer batching file writes and asset changes first, then call `refresh_unity` once at a natural synchronization point before compilation-dependent actions, console checks, or attaching newly created scripts.

Use `refresh_unity` when:
- Script files, assets, or project files were created or edited manually and Unity must import them.
- You need compilation results before continuing.
- Console verification depends on Unity having imported recent changes.

Avoid `refresh_unity` when:
- You only changed scene objects, components, transforms, cameras, or other data through MCP tools that already operate inside Unity.
- You are still making a series of related file edits that can be refreshed together.
- You only need to inspect current scene/editor state.

### 2. After Writing/Editing Scripts: Refresh Unity, Wait for Compilation, and Check Console

```python
# After manually creating or editing a script file:
# Do not use create_script, script_apply_edits, apply_text_edits,
# validate_script, delete_script, get_sha, or find_in_file.
# Create and edit the .cs file manually, then save it.

# 1. Refresh Unity and request compilation
refresh_unity(
    mode="if_dirty",             # "if_dirty" | "force"
    scope="scripts",             # "assets" | "scripts" | "all"
    compile="request",           # "none" | "request"
    wait_for_ready=True          # bool - wait until editor ready
)

# 2. Poll editor state until compilation completes
# Read mcpforunity://editor/state → wait until is_compiling == false
# Also wait if is_domain_reload_pending == true

# 3. Check for compilation errors
read_console(types=["error"], count=10, include_stacktrace=True)
```

**Why:** Unity must import and compile scripts before they're usable. `refresh_unity` is very slow, so batch related script/file edits first, then refresh once after saving. After the refresh, wait for compilation to finish and check the console.

### 3. Use `batch_execute` for Multiple Operations

```python
# 10-100x faster than sequential calls
batch_execute(
    commands=[
        {"tool": "manage_gameobject", "params": {"action": "create", "name": "Cube1", "primitive_type": "Cube"}},
        {"tool": "manage_gameobject", "params": {"action": "create", "name": "Cube2", "primitive_type": "Cube"}},
        {"tool": "manage_gameobject", "params": {"action": "create", "name": "Cube3", "primitive_type": "Cube"}}
    ],
    parallel=True  # Hint only: Unity may still execute sequentially
)
```

**Max 25 commands per batch by default (configurable in Unity MCP Tools window, max 100).** Use `fail_fast=True` for dependent operations.

**Tip:** Also use `batch_execute` for discovery — batch multiple `find_gameobjects` calls instead of calling them one at a time:
```python
batch_execute(commands=[
    {"tool": "find_gameobjects", "params": {"search_term": "Camera", "search_method": "by_component"}},
    {"tool": "find_gameobjects", "params": {"search_term": "Player", "search_method": "by_tag"}},
    {"tool": "find_gameobjects", "params": {"search_term": "GameManager", "search_method": "by_name"}}
])
```

### 4. Check Console After Major Changes

```python
read_console(
    action="get",
    types=["error", "warning"],  # Focus on problems
    count=10,
    format="detailed"
)
```

### 5. Always Check `editor_state` Before Complex Operations

```python
# Read mcpforunity://editor/state to check:
# - is_compiling: Wait if true
# - is_domain_reload_pending: Wait if true  
# - ready_for_tools: Only proceed if true
# - blocking_reasons: Why tools might fail
```

## Parameter Type Conventions

These are common patterns, not strict guarantees. `manage_components.set_property` payload shapes can vary by component/property; if a template fails, inspect the component resource payload and adjust.

### Vectors (position, rotation, scale, color)
```python
# Both forms accepted:
position=[1.0, 2.0, 3.0]        # List
position="[1.0, 2.0, 3.0]"     # JSON string
```

### Booleans
```python
# Both forms accepted:
include_inactive=True           # Boolean
include_inactive="true"         # String
```

### Colors
```python
# Auto-detected format:
color=[255, 0, 0, 255]         # 0-255 range
color=[1.0, 0.0, 0.0, 1.0]    # 0.0-1.0 normalized (auto-converted)
```

### Paths
```python
# Assets-relative (default):
path="Assets/Scripts/MyScript.cs"

# URI forms:
uri="mcpforunity://path/Assets/Scripts/MyScript.cs"
uri="file:///full/path/to/file.cs"
```

## Core Tool Categories

| Category | Key Tools | Use For |
|----------|-----------|---------|
| **Scene** | `manage_scene`, `find_gameobjects` | Scene operations, finding objects. Multi-scene editing (additive load, close, set active, move GO between scenes), scene templates (`3d_basic`, `2d_basic`, `empty`, `default`), scene validation with `auto_repair`. For build settings, use `manage_build(action="scenes")`. |
| **Objects** | `manage_gameobject`, `manage_components` | Creating/modifying GameObjects |
| **Scripts** | Manual file editing only | Create and edit `.cs` files manually. Do not use `create_script`, `script_apply_edits`, `apply_text_edits`, `validate_script`, `delete_script`, `get_sha`, or `find_in_file`. After saving script changes, use `refresh_unity`, wait for compilation, then check the console.
| **Assets** | `manage_asset`, `manage_prefabs` | Asset operations. **Prefab instantiation** is done via `manage_gameobject(action="create", prefab_path="...")`, not `manage_prefabs`. |
| **Editor** | `manage_editor`, `execute_menu_item`, `read_console` | Editor control, package deployment (`deploy_package`/`restore_package`), undo/redo (`undo`/`redo` actions) |
| **Testing** | `run_tests`, `get_test_job` | Unity Test Framework |
| **Batch** | `batch_execute` | Parallel/bulk operations |
| **Camera** | `manage_camera` | Camera management (Unity Camera + Cinemachine). **Tier 1** (always available): create, target, lens, priority, list, screenshot. **Tier 2** (requires `com.unity.cinemachine`): brain, body/aim/noise pipeline, extensions, blending, force/release. 7 presets: follow, third_person, freelook, dolly, static, top_down, side_scroller. Resource: `mcpforunity://scene/cameras`. Use `ping` to check Cinemachine availability. See [tools-reference.md](references/tools-reference.md#camera-tools). |
| **Graphics** | `manage_graphics` | Rendering and post-processing management. 33 actions across 5 groups: **Volume** (create/configure volumes and effects, URP/HDRP), **Bake** (lightmaps, light probes, reflection probes, Edit mode only), **Stats** (draw calls, batches, memory), **Pipeline** (quality levels, pipeline settings), **Features** (URP renderer features: add, remove, toggle, reorder). Resources: `mcpforunity://scene/volumes`, `mcpforunity://rendering/stats`, `mcpforunity://pipeline/renderer-features`. Use `ping` to check pipeline status. See [tools-reference.md](references/tools-reference.md#graphics-tools). |
| **Packages** | `manage_packages` | Install, remove, search, and manage Unity packages and scoped registries. Query actions: list installed, search registry, get info, ping, poll status. Mutating actions: add/remove packages, embed for editing, add/remove scoped registries, force resolve. Validates identifiers, warns on git URLs, checks dependents before removal (`force=true` to override). See [tools-reference.md](references/tools-reference.md#package-tools). |
| **ProBuilder** | `manage_probuilder` | 3D modeling, mesh editing, complex geometry. **When `com.unity.probuilder` is installed, prefer ProBuilder shapes over primitive GameObjects** for editable geometry, multi-material faces, or complex shapes. Supports 12 shape types, face/edge/vertex editing, smoothing, and per-face materials. See [ProBuilder Guide](references/probuilder-guide.md). |
| **UI** | `manage_ui`, `batch_execute` with `manage_gameobject` + `manage_components` | **UI Toolkit**: Use `manage_ui` to create UXML/USS files, attach UIDocument, inspect visual trees. **uGUI (Canvas)**: Use `batch_execute` for Canvas, Panel, Button, Text, Slider, Toggle, Input Field. **Read `mcpforunity://project/info` first** to detect uGUI/TMP/Input System/UI Toolkit availability. (see [UI workflows](references/workflows.md#ui-creation-workflows)) |
| **Docs** | `unity_reflect`, `unity_docs` | API verification and documentation lookup. **`unity_reflect`** inspects live C# APIs via reflection (requires Unity connection): `search` types across assemblies, `get_type` for member summary, `get_member` for full signatures. **`unity_docs`** fetches official docs from docs.unity3d.com (no Unity connection needed): `get_doc` (ScriptReference), `get_manual` (Manual pages), `get_package_doc` (package docs), `lookup` (parallel search all sources + project assets). **Trust hierarchy: reflection > project assets > docs.** Workflow: `unity_reflect` search -> get_type -> get_member -> `unity_docs` lookup. See [tools-reference.md](references/tools-reference.md#docs-tools). |

## Common Workflows

### Creating a New Script and Using It

```python
# 1. Create the script manually
# Manually create the file:
# Assets/Scripts/PlayerController.cs
#
# Add the following code directly into the script file:

"""
using UnityEngine;

public class PlayerController : MonoBehaviour
{
    public float speed = 5f;

    private void Update()
    {
        Vector3 movement = new Vector3(
            Input.GetAxis("Horizontal"),
            0f,
            Input.GetAxis("Vertical")
        );

        transform.Translate(movement * speed * Time.deltaTime);
    }
}
"""

# 2. Save the script file manually

# 3. Refresh Unity and request compilation
refresh_unity(
    mode="if_dirty",
    scope="scripts",
    compile="request",
    wait_for_ready=True
)

# 4. Wait for compilation to finish
# Read mcpforunity://editor/state → wait until is_compiling == false

# 5. Check for compilation errors
console = read_console(types=["error"], count=10)

if console["messages"]:
    print("Compilation errors:", console["messages"])
else:
    # 6. Only then attach to GameObject
    manage_gameobject(action="modify", target="Player", components_to_add=["PlayerController"])
```

### Finding and Modifying GameObjects

```python
# 1. Find by name/tag/component (returns IDs only)
result = find_gameobjects(search_term="Enemy", search_method="by_tag", page_size=50)

# 2. Get full data via resource
# mcpforunity://scene/gameobject/{instance_id}

# 3. Modify using the ID
manage_gameobject(action="modify", target=instance_id, position=[10, 0, 0])
```

### Running and Monitoring Tests

```python
# 1. Start test run (async)
result = run_tests(mode="EditMode", test_names=["MyTests.TestSomething"])
job_id = result["job_id"]

# 2. Poll for completion
result = get_test_job(job_id=job_id, wait_timeout=60, include_failed_tests=True)
```

## Pagination Pattern

Large queries return paginated results. Always follow `next_cursor`:

```python
cursor = 0
all_items = []
while True:
    result = manage_scene(action="get_hierarchy", page_size=50, cursor=cursor)
    all_items.extend(result["data"]["items"])
    if not result["data"].get("next_cursor"):
        break
    cursor = result["data"]["next_cursor"]
```

## Multi-Instance Workflow

When multiple Unity Editors are running:

```python
# 1. List instances via resource: mcpforunity://instances
# 2. Set active instance
set_active_instance(instance="MyProject@abc123")
# 3. All subsequent calls route to that instance
```

## Error Recovery
| Symptom | Cause | Solution |
|---------|-------|----------|
| Tools return "busy" | Compilation in progress | Wait, check `editor_state` |
| "stale_file" error | File changed since SHA | Do not use script editing tools; open the script manually and inspect the latest file contents before editing |
| Connection lost | Domain reload | Wait ~5s, reconnect |
| Commands fail silently | Wrong instance | Check `set_active_instance` |
| Script component cannot be attached | Script has not compiled yet or has errors  | Refresh Unity, wait for compilation, then check console errors                                                |
| Compilation errors appear | Manual script edit introduced invalid code | Open the script manually, fix the issue, save, refresh Unity, wait for compilation, then re-check console     |

## Reference Files

For detailed schemas and examples:

- **[tools-reference.md](references/tools-reference.md)**: Complete tool documentation with all parameters
- **[workflows.md](references/workflows.md)**: Extended workflow examples and patterns
