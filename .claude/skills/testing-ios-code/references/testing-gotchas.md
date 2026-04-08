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
