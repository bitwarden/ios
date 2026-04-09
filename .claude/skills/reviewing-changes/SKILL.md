---
name: reviewing-changes
description: Performs comprehensive code reviews for Bitwarden iOS projects, verifying architecture compliance, style guidelines, compilation safety, test coverage, and security requirements. Use when reviewing pull requests, checking commits, analyzing code changes, verifying Bitwarden coding standards, evaluating unidirectional data flow pattern, checking services container dependency injection usage, reviewing security implementations, or assessing test coverage. Automatically invoked by CI pipeline or manually for interactive code reviews.
---

# Reviewing Changes — Bitwarden iOS

## Instructions

Work systematically through each step before providing feedback. Each checklist loads only the relevant review strategy for the change type detected.

### Step 1: Retrieve Additional Details

Fetch any additional context using available tools (JIRA MCP, GitHub API). If the PR title and description don't provide enough context, request:
- A link to the JIRA ticket
- A GitHub issue reference
- More detail in the PR description

**iOS-specific metadata checks:**
- Screenshots required for any `*View.swift` changes that affect visible UI — flag as ❓ if absent
- If new `*Processor.swift` or `*Service.swift` is added with no test file, flag as ❓

### Step 2: Detect Change Type

**iOS-specific patterns:**
- **Feature Addition**: New `*Coordinator.swift`, `*Processor.swift`, `*View.swift` (full file-set); new screen or flow
- **Bug Fix**: Targeted changes to existing `*Processor.swift`, `*Service.swift`, or `*Repository.swift` files
- **UI Change**: Changes only to `*View.swift` files; no business logic changes
- **Refactoring**: Renamed/restructured files without new user-visible behavior
- **Dependency Update**: Changes to `Mintfile`, `project-*.yml` version references, `Package.swift`
- **Infrastructure**: Changes to `Scripts/`, `Configs/`, `.github/`, `fastlane/`

### Step 3: Load Appropriate Checklist

Based on detected type, read the relevant checklist file:

- **Dependency Update** → `checklists/dependency-update.md` (expedited review)
- **Bug Fix** → `checklists/bug-fix.md` (focused: fix correctness + regression test)
- **Feature Addition** → `checklists/feature-addition.md` (comprehensive: all areas)
- **UI Change** → `checklists/ui-change.md` (UDF compliance + accessibility + snapshots)
- **Refactoring** → Full architecture check: verify behavior-preserving via `reference/ios-architecture-patterns.md`
- **Infrastructure** → Security review + deployment impact assessment

The checklist provides: multi-pass review strategy, type-specific focus areas, what to check and what to skip.

### Step 4: Execute Review Following Checklist

Follow the checklist's review strategy, thinking through each pass systematically before writing feedback.

### Step 5: Consult Reference Materials As Needed

Load reference files only when needed for specific questions:

- **Re-reviews (incremental)** → invoke `reviewing-incremental-changes` agent skill; scope to changed lines only, do not flag new issues in unchanged code
- **Issue prioritization** → `reference/priority-framework.md` (Critical vs Important vs Suggested)
- **Phrasing feedback** → `reference/feedback-psychology.md` (questions vs commands, I-statements)
- **Architecture questions** → `reference/ios-architecture-patterns.md` + `Docs/Architecture.md`
- **Security questions** → `reference/ios-security-patterns.md`
- **Testing questions** → `reference/ios-testing-patterns.md`
- **Style questions** → `reference/ios-style-patterns.md`
- **Output format** → `examples/annotated-example.md`

## Core Principles

- **Priority order**: Security → Correctness → Breaking Changes → Performance → Maintainability
- **Appropriate depth**: Match review rigor to change complexity and risk. A dependency update doesn't need architecture review.
- **Specific references**: Always use `file:line_number` format for precise locations
- **Actionable feedback**: Say what to change and why — not just what's wrong
- **Efficient reviews**: Use the change-type checklist, skip what's not relevant
- **iOS patterns**: Validate UDF, Has* DI, store.binding, Sourcery mock conventions, StateProcessor subclass
