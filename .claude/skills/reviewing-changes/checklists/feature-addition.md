# Feature Addition Review Checklist

Use for: New `*Coordinator.swift`, `*Processor.swift`, `*View.swift` (full file-set); new screens or flows.

## Multi-Pass Strategy

### First Pass: High-Level Assessment

**1. Understand the feature:**
- Read PR description — what problem does this solve?
- Identify user-facing changes vs internal changes
- Note any security implications (auth, encryption, Keychain, vault data)

**2. Scan file structure:**
- Are all 7 required files present? (Coordinator, Processor, State, Action, Effect, View, Route)
- Placed in the correct domain folder under `Core/` or `UI/`?
- No new top-level subdirectories in `Core/` or `UI/`?

**3. Initial risk assessment:**
- Does this touch sensitive data, Keychain, or SDK crypto?
- Does this run in an app extension (memory limit implications)?
- Any obvious UDF violations or force-unwraps?

### Second Pass: Architecture Deep-Dive

Read `reference/ios-architecture-patterns.md` for full patterns and code examples.

**Check these four areas:**
- **UDF/StateProcessor**: Views send Actions/Effects only — never mutate state; `store.binding(get:send:)` for all SwiftUI bindings; `receive(_:)` sync, `perform(_:)` async
- **Has* DI**: `Services` typealias uses only needed `Has*` protocols; no `any` type; `ServiceContainer` is the only DI root
- **Domain placement**: Files in correct `Core/` or `UI/` subdomain; no new top-level subdirectories in `Core/` or `UI/`
- **Error handling**: `coordinator.showErrorAlert(error:)` for consistent presentation; sensitive errors implement `NonLoggableError`

### Third Pass: Security and Quality

**4. Security (see `reference/ios-security-patterns.md` for detail):**
- No unencrypted vault data logged, stored, or transmitted
- Sensitive credentials stored via `KeychainRepository`, not `UserDefaults`
- All user input validated via `InputValidator`
- Extension memory impact checked if KDF/Argon2id is involved

**5. Testing:**
- Processor tests cover: action paths (state mutations), effect paths (async work), error paths
- `ServiceContainer.withMocks(...)` used for test setup
- New protocols have `// sourcery: AutoMockable` annotation
- Test files co-located with implementation files

**6. Code Quality:**
- All new public types/methods have DocC (`///`) documentation
- `TODO` comments include JIRA ticket reference
- `Has*` / `Default*` / `Mock*` naming conventions followed

## Prioritizing Findings

See `reference/priority-framework.md` to classify as Critical/Important/Suggested/Optional.

## Providing Feedback

See `reference/feedback-psychology.md` for phrasing guidance and when to be prescriptive vs. ask questions.

## Output Format

See `examples/annotated-example.md` for the required output format and inline comment structure.
