---
description: Execute a complete Bitwarden iOS implementation workflow from ticket to PR. Loads or creates a plan, implements, tests, builds, runs preflight, commits, and opens a PR with labels.
argument-hint: <PM-XXXXX ticket ID or task description>
---

# Work on iOS: $ARGUMENTS

Full implementation workflow with user confirmation at each phase boundary.

## Phase 1: Load or Create Plan

Check for an existing plan at `.claude/outputs/plans/`:
- **If found**: Load it and present a summary to the user
- **If not found**: Invoke `/plan-ios-work $ARGUMENTS` to create one

**Confirm**: "Plan loaded/created. Ready to begin implementation? (y/n)"

## Phase 2: Implement

Invoke the `implementing-ios-code` skill:
- Follow the dependency-ordered phases from the plan (Core → Services → Processors → Views → DI wiring)
- Use `templates.md` for file-set skeletons
- Apply the security checklist as each layer is completed

**Confirm**: "Implementation complete. Proceed to writing tests? (y/n)"

## Phase 3: Write Tests

Invoke the `testing-ios-code` skill:
- Write processor tests (action/effect paths, error paths)
- Write service/repository tests
- Add `// sourcery: AutoMockable` to new protocols and run Sourcery

**Confirm**: "Tests written. Proceed to build verification? (y/n)"

## Phase 4: Build and Verify

Invoke the `build-test-verify` skill:
- Generate Xcode projects if needed
- Run lint: `mint run swiftlint`
- Run format check: `mint run swiftformat --lint --lenient .`
- Run spell check: `typos`
- Build the project
- Run tests for affected modules

Fix any failures before proceeding.

**Confirm**: "Build and tests pass. Proceed to preflight? (y/n)"

## Phase 5: Preflight

Invoke the `perform-ios-preflight-checklist` skill:
- Run automated checks
- Complete the manual checklist (architecture, security, testing, docs, hygiene)

**Confirm**: "Preflight complete. Proceed to commit? (y/n)"

## Phase 6: Commit

Invoke the `committing-ios-changes` skill:
- Stage specific changed files
- Write commit message in `[PM-XXXXX] <type>: Description` format
- Create commit

**Confirm**: "Committed. Proceed to create PR? (y/n)"

## Phase 7: Create PR and Label

Invoke the `creating-ios-pull-request` skill:
- Push branch to remote
- Create draft PR with Tracking/Objective template

Invoke the `labeling-ios-changes` skill:
- Add change type label (`t:feature-app`, `t:bug`, `t:tech-debt`, etc.)
- Add app context label (`app:password-manager`, `app:authenticator`)

**Final output**: "Draft PR created: <URL>. Review your changes and mark ready when satisfied."
