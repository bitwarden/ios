# Style Checklist — Bitwarden iOS

Bitwarden-specific style rules enforced by tooling. Do not flag issues that SwiftLint/SwiftFormat catch automatically.

## Naming Conventions

- [ ] DI protocols use `Has*` prefix (e.g., `HasAuthRepository`)
- [ ] Default implementations use `Default*` prefix (e.g., `DefaultAuthService`)
- [ ] Test mocks use `Mock*` prefix (e.g., `MockAuthService`)
- [ ] Test methods follow `test_<functionName>_<behaviorDescription>` pattern

## TODO Comments

- [ ] All `TODO` comments include a JIRA ticket: `// TODO: PM-12345 - description`
- [ ] `todo_without_jira` SwiftLint rule enforced — missing tickets will block CI
- [ ] The referenced ticket is **the ticket where the work will actually land**, not the umbrella epic. Pointing a TODO at a long-lived parent ticket leaves it adrift after the parent closes; pointing it at the specific child PR/ticket gives a future reader a closable signal.

## Alphabetization

Source: [contributing.bitwarden.com — Swift style: Alphabetization](https://contributing.bitwarden.com/contributing/code-style/swift#alphabetization).

- [ ] Enum cases are alphabetized — unless the raw type encodes ordering (e.g., `Int` raw values that line up with server error codes or persisted indices). Document the carve-out inline if you take it.
- [ ] Tests within a test file are alphabetized by function name. Within a group of tests for the same function, error-case tests are commonly placed at the end of the group rather than strictly alphabetized.
- [ ] Static members and computed properties within a section are alphabetized.

Protocol conformance ordering is **not** an enforced project rule; don't flag it during review even if a reviewer expresses a personal preference.

## Comments

- [ ] Comments document *why the current code is the way it is* — invariants, hidden constraints, surprising decisions. They do not narrate what future PRs will add.
- [ ] Avoid multi-paragraph blocks that pre-stage upcoming work ("Part 2/3 will wire this; Part 3/3 will…"). The PR description and the linked ticket carry that context. Comments rot when the plan changes; tickets don't.
- [ ] If a TODO captures the future intent, the TODO line is the comment — no surrounding prose needed.

## Localization

Source: [contributing.bitwarden.com — Swift style: Localization](https://contributing.bitwarden.com/contributing/code-style/swift#localization).

- [ ] Localization keys mirror the English string closely. `Archive` for "Archive", not `MoveToArchive` or `ArchiveTitle`.
- [ ] Translator-facing comments (`/* … */` above a key) describe meaning, placement, or constraints that affect translation — not internal phasing or ticket bookkeeping. Translators are the audience.

## Module Imports

- [ ] `BitwardenSdk` imported for SDK types (ciphers, keys, crypto operations)
- [ ] `BitwardenKit` imported for shared utilities (Store, StateProcessor, Coordinator, Alert)
- [ ] `BitwardenResources` imported for shared assets, fonts, localizations
- [ ] Imports grouped: system frameworks → third-party → project modules

## Documentation

- [ ] All new public types/methods have DocC (`///`) documentation
- [ ] Exception: Protocol property/function implementations (docs live in the protocol)
- [ ] Exception: Mock classes (no docs required)
- [ ] `// MARK: -` sections used to organize code within files

## What NOT to Flag

- Formatting issues (SwiftFormat handles 4-space indent, trailing commas, etc.)
- Import ordering within groups (SwiftFormat handles this)
- General Swift naming conventions (camelCase, PascalCase) — flag only Bitwarden-specific prefixes
