# Review Psychology: Constructive Feedback Phrasing

Effective code review feedback is clear, actionable, and constructive.

## Phrasing Templates

### Critical Issues (Prescriptive)

**Pattern**: State problem + Provide solution + Explain why

```
**[file:line]** — CRITICAL: [Issue description]

[Specific fix or code example]

[Rationale explaining why this is critical]

Reference: [Docs/Architecture.md#section or skill reference]
```

**Example**:
```
**BitwardenShared/UI/Auth/VaultUnlock/VaultUnlockProcessor.swift:87** — CRITICAL: PIN stored in UserDefaults

Store via KeychainRepository instead:
    try await services.keychainRepository.setUserPin(pin, userId: userId)

UserDefaults is accessible to backup systems and other apps on the same device.

Reference: Docs/Architecture.md#security
```

---

### Suggested Improvements (Exploratory)

**Pattern**: Observe + Suggest + Explain benefit

```
**[file:line]** — Consider [alternative approach]

[Current observation]
Can we [specific suggestion]?

[Benefit or rationale]
```

**Example**:
```
**BitwardenShared/UI/Auth/Login/LoginView.swift:89** — Consider using existing BitwardenTextField

This custom text field looks similar to BitwardenKit/UI/Components/BitwardenTextField.swift:45.
Can we use the shared component to keep the UI consistent across the app?
```

---

### Questions (Collaborative)

**Pattern**: Ask + Provide context

```
**[file:line]** — [Question about intent or approach]?

[Optional context or observation]
```

**Example**:
```
**BitwardenShared/UI/Vault/VaultListProcessor.swift:134** — How does this handle the case where state is updated mid-effect?

It looks like `perform(.appeared)` and `perform(.refreshVault)` could both be in flight simultaneously.
Is there a mechanism to prevent duplicate refreshes, or is that handled at the service layer?
```

---

### Test Suggestions

**Pattern**: Observe gap + Suggest specific test + Provide skeleton

```
**[file:line]** — Consider adding test for [scenario]

[Rationale]

```swift
@MainActor
func test_<functionName>_<behaviorDescription>() async throws {
    // Test skeleton
}
```
```

**Example**:
```
**BitwardenShared/UI/Auth/Login/LoginProcessor.swift** — Consider adding test for invalid email error path

This would prevent regression of the validation guard you just added:

```swift
@MainActor
func test_continuePressed_invalidEmail_showsAlert() async {
    subject.state.email = "not-an-email"
    await subject.perform(.continuePressed)
    XCTAssertEqual(coordinator.alertShown.last, .invalidEmail)
}
```
```

---

## When to Be Prescriptive vs Ask Questions

**Be Prescriptive** (tell them what to do):
- Security rule violations (zero-knowledge, Keychain)
- UDF architecture violations (state mutation in Views)
- Documented project standards (Has*, Default*, Mock* naming)
- Compilation errors, force-unwraps
- Missing required documentation

**Ask Questions** (seek explanation):
- Design decisions with multiple valid approaches
- Intent or reasoning is genuinely unclear
- Scope decisions (this PR vs future work)
- Patterns not documented in project guidelines

---

## Special Cases

**Nitpicks** — Use "Nit:" prefix for truly minor suggestions:
```
**Nit**: Extra blank line at BitwardenShared/UI/Vault/VaultView.swift:145
```

**Uncertainty** — If unsure, acknowledge it:
```
I'm not certain, but this could be called frequently in tight loops.
Has this been profiled, or is the cost negligible?
```

**Positive Feedback** — Brief list only, no elaboration:
```
## Good Practices
- Correct StateProcessor subclass with proper receive/perform separation
- Services typealias scoped to only needed Has* protocols
- All new types have DocC documentation
```
