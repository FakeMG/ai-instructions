---
name: reviewing-tests
description: >
  This skill is for reviewing the *tests* of a Unity project against the project's testing guidelines (the `unity-testing` skill).
  Only trigger when the user is explicitly requesting this skill. Otherwise, don't use it.
---

# Test Review Skill

Use this skill for an unusually strict review focused on test quality, coverage of behavior, isolation, and test-suite health.

**Before starting, read and follow the `multi-agent-review` skill (`../multi-agent-review/SKILL.md`).** It defines how sub-agents are spawned, how their reports are synthesized, and the required output format. This skill supplies the inputs that skill requires, listed below.

Above all, this skill should push the reviewer to be rigorous about what the tests actually prove. Do not merely check that tests exist or that they pass.
- Look for tests that could not fail: no meaningful assertion, assertions on the mock instead of the unit under test, or assertions that would pass for a broken implementation.
- Look for missing tests, not just flawed ones. Behavior that no test pins down is a finding.

Pass this stance to every sub-agent.

## Inputs for `multi-agent-review`

### Rubric source

Read the `unity-testing` skill (`../unity-testing/SKILL.md`) and identify every guideline in it.

- Each section header is a criterion, except `What to Test`, where each of its five categories is its own criterion.
- Name each sub-agent after its guideline. Give it the full section text and have it check every bullet.
- Do not skip any guideline. If one does not apply, explicitly state why.
- Guidelines written as instructions to the test author (e.g. "STOP and notify the user") are reviewed as requirements on the result.
- Apply each guideline to the kind of test under review (project integration test vs. individual system).

### Subject

The tests the user points at (test files, a test folder, or a test assembly), together with the production code those tests cover. The production code is needed to judge coverage, testability, and whether the tests only touch the public contract. Review only. Do not modify the tests or the code under test.

### Model

GPT-6 Luna Max as default.

### Severity definitions

- 🔴 **Critical**: Gives false confidence or breaks the suite: a test that cannot fail, a test of private or internal members, state leaking or order-dependent tests, a missing category of coverage for a system, or a MonoBehaviour tested in EditMode
- 🟡 **Significant**: Slows development, makes tests brittle or hard to maintain, or violates a structural guideline: poor isolation, unmocked external dependencies, complex logic inside tests, wrong test location, prefab or container misuse
- 🟢 **Minor**: Worth fixing, but won't hurt until the suite grows: naming, Arrange/Act/Assert layout, small clarity issues

### Terminology

In the engine's templates, "criterion" means "testing guideline", "subject" means "the tests (and the code they cover)", and the report title is "Test Review: [test file/folder name or system name]".