# Finding Priority Framework

Use this framework to classify findings during code review. Clear prioritization helps authors triage and address issues effectively.

## Severity Categories

- [❌ CRITICAL (Blocker - Must Fix Before Merge)](#critical)
- [⚠️ IMPORTANT (Should Fix)](#important)
- [♻️ DEBT (Technical Debt)](#debt)
- [🎨 SUGGESTED (Nice to Have)](#suggested)
- [❓ QUESTION (Seeking Clarification)](#question)
- [Optional (Acknowledge But Don't Require)](#optional)

---

## ❌ CRITICAL (Blocker - Must Fix Before Merge)

Must be addressed before the PR can be merged. Immediate risk to security, stability, or architecture integrity.

### Security
- Unencrypted vault data logged, stored, or transmitted
- Sensitive credentials in `UserDefaults`/`CoreData` instead of Keychain
- Missing `InputValidator` for external/user input
- Hardcoded API keys or tokens
- SDK crypto bypassed with custom implementation

**Example**:
```
BitwardenShared/UI/Auth/VaultUnlock/VaultUnlockProcessor.swift:87 — CRITICAL: PIN stored in UserDefaults
PIN must be stored via KeychainRepository, not UserDefaults. Exposes credential to backup systems and other apps.
```

### Stability
- Force-unwraps (`try!`, `!`) in production code paths
- Missing error handling for network/SDK calls
- Thread-safety violations (main actor violations, data races)

### Architecture
- View mutating state directly (UDF violation)
- Business logic placed in Coordinator instead of Processor
- New top-level subdirectory added to `Core/` or `UI/`
- `any` type used for protocol-based dependencies
- Zero-knowledge principle violated

**Example**:
```
BitwardenShared/UI/Vault/VaultView.swift:44 — CRITICAL: Direct state mutation in View
Views must send Actions/Effects through the Store. Change to: store.send(.itemDeleted(id))
```

---

## ⚠️ IMPORTANT (Should Fix)

Should be addressed but won't block merge if there's a compelling reason.

### Testing
- Missing tests for new Processor actions/effects
- Error paths untested (only happy path covered)
- No regression test for the bug being fixed
- New protocol missing `// sourcery: AutoMockable`

**Example**:
```
BitwardenShared/UI/Auth/Login/LoginProcessorTests.swift — IMPORTANT: Missing test for invalid email error path
Add test for coordinator.showAlert(.invalidEmail) when email fails validation.
```

### Architecture
- `Services` typealias over-injected (includes protocols not used by this processor)
- Inconsistent error handling (mix of `coordinator.showErrorAlert` and custom alerts)
- Poor separation of concerns between Processor and Service

### Documentation
- Public types/methods missing DocC (`///`) documentation
- Complex logic without explanatory comments
- `TODO` comment missing JIRA ticket (fails `todo_without_jira` lint rule)

---

## ♻️ DEBT (Technical Debt)

Introduces technical debt that should be tracked for future cleanup.

### Duplication
- Copy-pasted logic across Processors (extract to shared Service)
- Repeated validation code that should be in `InputValidator`

**Example**:
```
BitwardenShared/UI/Vault/AddEdit/AddEditItemProcessor.swift:156 — DEBT: Duplicates URL validation
Same pattern exists in SendProcessor.swift:234. Extract to InputValidator.
```

### Convention Violations
- Inconsistent naming (`CreateItemProcessor` instead of `AddEditItemProcessor`)
- Missing `Default*` prefix on concrete service implementations
- Mock not following `Mock*` prefix convention

---

## 🎨 SUGGESTED (Nice to Have)

Improvements with measurable value only. A finding qualifies as SUGGESTED if it provides: security gain, cyclomatic complexity reduction, bug class prevention, or elimination of an O(n²) pattern. Subjective style preferences, vague simplifications, and naming nitpicks do not qualify — leave those out entirely or raise in conversation.

- Extractable duplicated logic that reduces measurable complexity or improves testability
- Patterns that would prevent a recurring bug class in this module
- Using an existing `BitwardenKit/UI/` component where a custom one duplicates it (measurable duplication reduction)

**Example**:
```
BitwardenShared/UI/Auth/Login/LoginView.swift:89 — SUGGESTED: Consider BitwardenTextField
This custom text field duplicates BitwardenKit/UI/Components/BitwardenTextField. Using the existing component reduces duplication and ensures consistent validation behaviour across screens.
```

---

## ❓ QUESTION (Seeking Clarification)

Design decisions or intent that requires human input — cannot be resolved by code inspection alone.

- Multiple valid implementation approaches with unclear preference
- Ambiguous acceptance criteria or edge case behavior
- Potential conflict with another in-flight PR

**Example**:
```
BitwardenShared/UI/Vault/VaultListProcessor.swift:67 — QUESTION: Expected sort for equal modification timestamps?
Spec doesn't specify tie-breaking. Should secondary sort be by name (alphabetical) or creation order?
```

---

## Optional (Acknowledge But Don't Require)

Note good practices briefly. **Single bullet list only — no elaboration.**

```markdown
## Good Practices
- Correct StateProcessor subclass with proper receive/perform separation
- Services typealias scoped to only needed Has* protocols
- All new types have DocC documentation
```

---

## Classification Guidelines

### When Something is Between Categories

| Unsure between | Ask |
|----------------|-----|
| Critical vs Important | "Could this cause a security breach, data loss, or crash in production?" If yes → Critical |
| Important vs Debt | "Is this a defect or just duplication/inconsistency?" Defect → Important |
| Important vs Suggested | "Would I block merge over this?" If yes → Important |
| Debt vs Suggested | "Will this require rework within 6 months?" If yes → Debt |
| Suggested vs Question | "Am I requesting a change or asking for clarification?" Change → Suggested |

### Special Cases

- **Tech debt in surrounding code**: Acknowledge but don't require fixing in unrelated PRs. Exception: if the change makes existing debt worse.
- **Scope creep**: Don't request changes outside the PR's stated scope. Note as "Future consideration" at most.
- **Linter-catchable issues**: Don't flag issues that SwiftLint/SwiftFormat catch automatically.

---

## Summary

| Severity | Meaning |
|----------|---------|
| ❌ CRITICAL | Block merge — security, stability, architecture |
| ⚠️ IMPORTANT | Should fix — testing, quality, documentation |
| ♻️ DEBT | Technical debt introduced — track for cleanup |
| 🎨 SUGGESTED | Nice to have — effort vs. benefit judgment call |
| ❓ QUESTION | Clarification needed — human decision required |
| Optional | Good practice — brief acknowledgment only |
