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
