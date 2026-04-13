---
name: perform-ios-preflight-checklist
description: Perform preflight checks, pre-commit check, self review, or verify changes are ready to commit for Bitwarden iOS. Use when asked to "preflight", "pre-commit check", "self review", "ready to commit", "check my changes", or before creating a PR.
---

# iOS Pre-flight Checklist

Run this before every commit or PR.

## Automated Checks (Run These First)

```bash
mint run swiftformat --lint --lenient .  # Formatting
mint run swiftlint                        # Lint
typos                                     # Spell check
```

Fix any failures before continuing.

## Manual Checklist

### Architecture
- [ ] UDF respected: views send actions/effects, never mutate state directly
- [ ] Business logic in Processor; navigation logic in Coordinator
- [ ] No new top-level subdirectories in `Core/` or `UI/`
- [ ] `Services` typealias uses only the `Has*` protocols this processor needs

### Security
- [ ] Zero-knowledge: no unencrypted vault data logged, stored, or transmitted
- [ ] Secrets use `KeychainRepository`, not `UserDefaults`/`CoreData`
- [ ] User input validated via `InputValidator`
- [ ] Sensitive errors implement `NonLoggableError`
- [ ] Extension memory impact checked if KDF is involved

### Testing
- [ ] New processor actions/effects have tests
- [ ] Error paths tested (not just happy path)
- [ ] New protocols have `// sourcery: AutoMockable`
- [ ] Test files co-located with implementation files

### Documentation & Style
- [ ] All new public types/methods have DocC (`///`) documentation
- [ ] `TODO` comments include JIRA ticket: `// TODO: PM-12345 - description`
- [ ] Imports grouped: system → third-party → project modules
- [ ] `Has*` / `Default*` / `Mock*` naming conventions followed

### Hygiene
- [ ] No hardcoded secrets, credentials, or API keys
- [ ] No `try!` or force-unwraps (`!`) in production code paths
- [ ] No unintended changes to `project-*.yml` specs

## All Green?

Proceed to commit using the `committing-ios-changes` skill.
