# Testing Gotchas — Bitwarden iOS

Non-obvious, iOS/Bitwarden-specific facts that cause test failures.
Only pre-populated with confirmed codebase-specific behaviour.

## Snapshot Tests Are Globally Disabled (XCTest)

In XCTest files, snapshot test function names must be prefixed with `disabletest_` (not `test_`).
The full prefix is `disabletest_`, not just `disable`.

```swift
// ✅ Correct
func disabletest_snapshot_empty() { ... }

// ❌ Wrong — will run as a test and fail
func test_snapshot_empty() { ... }

// ❌ Wrong prefix — won't be recognized
func disable_snapshot_empty() { ... }
```

> **Swift Testing note**: Snapshot tests currently remain XCTest-based (they depend on `SnapshotTesting` + `BitwardenTestCase`). As Swift Testing adoption grows, disabling may shift to traits (e.g., `.disabled()`). For now, always use XCTest with `disabletest_` prefix for snapshot tests.

## Simulator Requirements

Tests must run on the simulator specified in:
- `.test-simulator-device-name` — device model (e.g., "iPhone 16")
- `.test-simulator-ios-version` — iOS version (e.g., "18.2")

Snapshot test failures with image differences almost always mean the wrong simulator is selected.

## BitwardenTestError

`BitwardenTestError` is a test-only error type available in `TestHelpers/Support/`:

```swift
public enum BitwardenTestError: Equatable, LocalizedError {
    case example
    case mock(String)
}
```

Use `BitwardenTestError.example` as the standard generic test error. Use `.mock("description")` when you need distinct errors in a single test.

## Test Execution Order Is Randomized

Test plans use `randomExecutionOrder: true`. Tests must be fully independent — no shared mutable state between tests, no assumptions about execution order.

## @MainActor on Async Processor/Coordinator Tests

Processor and coordinator tests that call `perform(_:)` or `navigate(to:)` must be marked `@MainActor`:

```swift
// ✅ Correct
@MainActor
func test_perform_appeared_loadsData() async {
    await subject.perform(.appeared)
    XCTAssertEqual(subject.state.items.count, 1)
}
```

Service tests do NOT need `@MainActor` unless the service itself dispatches to main.

## Don't Test Swift-Synthesized Conformances

Tests should pin behavior the project owns — server contracts, custom encoding, branch logic, side effects. They should not exercise Swift's auto-synthesized conformances, which the language guarantees:

- For a `String`-backed enum, `Codable` synthesis serializes each case as `"<rawValue>"`. Writing a `codable_roundTrip` test only verifies the language; it doesn't catch a bug we could realistically introduce.
- `CaseIterable` synthesis populates `allCases` in declaration order. A test asserting `allCases == [.a, .b, .c]` is asserting against the language, not against project intent.

When the on-wire shape matters (and it usually does for Codable enums), the test that earns its keep is the one that pins each case's `rawValue` to the **server contract**:

```swift
@Test
func rawValues_matchServerContract() {
    #expect(Status.active.rawValue == "active")
    #expect(Status.archived.rawValue == "archived")
    // ... one assertion per case
}
```

If a case is renamed or its `rawValue` accidentally diverges from the server, this test fails and points the reader straight at the contract — without the noise of also re-testing `JSONEncoder`.

**Carve-outs.** Write the round-trip test when:
- The encoding is **not** synthesized (custom `encode(to:)`/`init(from:)`, custom `CodingKeys`, key-encoding strategies on the encoder).
- The shape is non-obvious (nested types, polymorphic discriminators, `@DocumentID`-style wrappers).
- The round-trip pins behavior across a serialization boundary the project actually controls.
