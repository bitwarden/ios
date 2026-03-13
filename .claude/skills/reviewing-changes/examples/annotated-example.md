# Review Output Examples — Bitwarden iOS

Well-structured code reviews demonstrating appropriate depth, tone, and formatting.

## Quick Format Reference

### Inline Comment Format (REQUIRED)

**Use `<details>` tags.** Only severity + one-line description visible; all other content collapsed.

```
[emoji] **[SEVERITY]**: [One-line issue description]

<details>
<summary>Details and fix</summary>

[Code example or specific fix]

[Rationale explaining why]

Reference: [Docs/Architecture.md#section or skill]
</details>
```

**Severity levels:**
- ❌ **CRITICAL** — Blocking, must fix (security, crashes, architecture violations)
- ⚠️ **IMPORTANT** — Should fix (missing tests, quality issues)
- ♻️ **DEBT** — Technical debt (duplication, convention violations)
- 🎨 **SUGGESTED** — Nice to have (refactoring, improvements)
- ❓ **QUESTION** — Seeking clarification (requirements, design decisions)

### Summary Comment Format

Uses the agent's `posting-review-summary` skill format. Surface ❌ CRITICAL issues at the top level for immediate visibility, wrap the full findings list in `<details>` for scannability.

```
**Overall Assessment:** APPROVE / REQUEST CHANGES

[1-2 neutral sentences describing what was reviewed]

**Critical Issues** (if any):
- ❌ [One-line summary with file:line]

<details>
<summary>All findings</summary>

- ❌ **CRITICAL**: [description] (`file:line`)
- ⚠️ **IMPORTANT**: [description] (`file:line`)
- ♻️ **DEBT**: [description] (`file:line`)
- 🎨 **SUGGESTED**: [description] (`file:line`)
- ❓ **QUESTION**: [description] (`file:line`)
</details>
```

For clean PRs with no findings, omit both sections — verdict + 1-2 sentences is sufficient.

**GitHub pitfall**: Never use `#` followed by a number in comment text (e.g., `#42`, `#PR123`). GitHub autolinks these to issues/PRs. Use `Finding 1:` or `item 42` instead.

---

## Example 1: Clean PR (No Issues)

**Context**: Small refactoring that moves shared logic to a service.

**Review:**
```markdown
**Overall Assessment:** APPROVE

Clean extraction of vault item formatting logic to VaultItemFormattingService, eliminating duplication between VaultListProcessor and SearchProcessor.
```

**Why this works:** Immediate verdict. One sentence. No elaborate praise sections. Author gets fast feedback and can proceed.

---

## Example 2: Bug Fix with Missing Regression Test

**Context**: Fix for incorrect TOTP code display when switching accounts.

**Summary Comment:**
```markdown
**Overall Assessment:** REQUEST CHANGES

**Critical Issues:**
- Fix doesn't prevent regression — no test added for account-switch scenario (TOTPCodeProcessor.swift:134)

See inline comments for details.
```

**Inline Comment** (on `BitwardenShared/UI/Auth/TOTP/TOTPCodeProcessor.swift:134`):
```markdown
⚠️ **IMPORTANT**: Missing regression test for the account-switch fix

<details>
<summary>Details and fix</summary>

A test that reproduces the original bug would prevent this from regressing:

```swift
@MainActor
func test_appeared_afterAccountSwitch_loadsTOTPCodeForNewAccount() async {
    let newUserId = "user-456"
    stateService.activeAccount = Account.fixture(userId: newUserId)

    await subject.perform(.appeared)

    XCTAssertEqual(totpService.getTOTPCodeCalled, true)
    XCTAssertEqual(totpService.lastRequestedUserId, newUserId)
}
```

Without this, the fix could silently regress if the TOTP loading path changes.
</details>
```

---

## Example 3: Feature Addition with Critical Issues

**Context**: Implements PIN unlock for vault access.

**Summary Comment:**
```markdown
**Overall Assessment:** REQUEST CHANGES

**Critical Issues:**
- PIN stored in UserDefaults — security violation (VaultUnlockProcessor.swift:87)
- Direct state mutation in VaultUnlockView — UDF violation (VaultUnlockView.swift:34)

See inline comments for all issues.
```

**Inline Comment 1** (on `BitwardenShared/UI/Auth/VaultUnlock/VaultUnlockProcessor.swift:87`):
```markdown
❌ **CRITICAL**: PIN stored in UserDefaults — SECURITY VIOLATION

<details>
<summary>Details and fix</summary>

PIN must be stored via `KeychainRepository`, not `UserDefaults`. UserDefaults is accessible to backup systems and other apps on a rooted device.

```swift
// ❌ CURRENT — plaintext in UserDefaults
UserDefaults.standard.set(pin, forKey: "userPIN")

// ✅ FIX — encrypted in Keychain
try await services.keychainRepository.setUserPin(pin, userId: userId)
```

Reference: Docs/Architecture.md#security
</details>
```

**Inline Comment 2** (on `BitwardenShared/UI/Auth/VaultUnlock/VaultUnlockView.swift:34`):
```markdown
❌ **CRITICAL**: Direct state mutation in View — UDF violation

<details>
<summary>Details and fix</summary>

Views must send Actions or Effects through the Store — never mutate state directly.

```swift
// ❌ CURRENT — bypasses the store
@State private var pin: String = ""
SecureField("PIN", text: $pin)

// ✅ FIX — binding backed by store state
SecureField("PIN", text: store.binding(
    get: \.pin,
    send: VaultUnlockAction.pinChanged
))
```

Reference: Docs/Architecture.md#unidirectional-data-flow
</details>
```

**Inline Comment 3** (on `BitwardenShared/UI/Auth/VaultUnlock/VaultUnlockProcessorTests.swift`):
```markdown
⚠️ **IMPORTANT**: Missing test for incorrect PIN error path

<details>
<summary>Details and fix</summary>

The happy path (correct PIN) is tested but the error path isn't:

```swift
@MainActor
func test_continuePressed_incorrectPIN_showsErrorAlert() async {
    subject.state.pin = "0000"
    keychainRepository.getUserPinResult = .failure(KeychainError.invalidPIN)

    await subject.perform(.continuePressed)

    XCTAssertNotNil(coordinator.alertShown.last)
}
```
</details>
```

**Inline Comment 4** (on `BitwardenShared/UI/Auth/VaultUnlock/VaultUnlockView.swift:89`):
```markdown
❓ **QUESTION**: Can we use the existing `BitwardenTextField` component?

<details>
<summary>Details</summary>

This PIN input field looks similar to `BitwardenKit/UI/Components/BitwardenTextField.swift:45`.
Would using the existing component maintain visual consistency across the app?
</details>
```

---

## ❌ Anti-Patterns to Avoid

### Problem: Verbose Summary with Multiple Sections

**What NOT to do:**
```markdown
## Review Complete ✅

## Summary
[Lengthy description of what the PR does]

### Strengths 👍
1. **Excellent StateProcessor structure** — The processor correctly separates...
[7 items with elaboration]

### Critical Issues ⚠️
- Missing test coverage...

### Architecture Compliance ✅
- UDF pattern correctly followed...
```

**Why this is wrong:** 800+ tokens for a summary comment. Elaborate praise sections. Duplicates inline comment details. Buries the actual issues.

**Correct approach:**
```markdown
**Overall Assessment:** REQUEST CHANGES

**Critical Issues:**
- Missing test coverage for PIN validation path (VaultUnlockProcessor.swift:87)

See inline comments for details.
```

### Problem: Praise-Only Inline Comments

**What NOT to do:** Creating an inline comment just to say `👍 Excellent StateProcessor usage here!`

**Why this is wrong:** Reserve inline comments for issues requiring attention. Positive feedback belongs in the brief summary bullet list — never in inline comments.

### Problem: Missing `<details>` Tags

**What NOT to do:**
```markdown
❌ **CRITICAL**: PIN stored without encryption

The `UserDefaults.standard.set(pin, ...)` call on line 87 stores the PIN in plaintext.
This exposes the credential to:
1. iOS backup systems
2. Other apps on a rooted device

Fix: Use `KeychainRepository.setUserPin(...)` instead.
[Long code example visible immediately]
```

**Why this is wrong:** All content visible immediately. Creates visual clutter when scanning multiple issues.

**Correct approach:** Severity + one-line description visible. All details collapsed in `<details>`.

---

## Summary

**Always:**
- Minimal summary (verdict + critical issues list, 5-10 lines max)
- Separate inline comments with `<details>` tags for each issue
- Emoji + text severity prefix (❌ CRITICAL, ⚠️ IMPORTANT, etc.)
- `file:line_number` references for all findings

**Never:**
- Multiple summary sections (Strengths, Architecture Compliance, etc.)
- Praise-only inline comments
- Duplication between summary and inline comments
- Full details visible without `<details>` collapse
