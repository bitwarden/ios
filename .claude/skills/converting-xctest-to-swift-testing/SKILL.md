---
name: converting-xctest-to-swift-testing
description: Convert an XCTest file to Swift Testing framework. Use when asked to "convert to Swift Testing", "migrate XCTest", "convert test file", "xctest to swift testing", "migrate tests to Swift Testing", or when explicitly asked to convert existing XCTest-based tests.
---

# Converting XCTest to Swift Testing

Use this skill to convert an existing XCTest file to the Swift Testing framework following Bitwarden iOS patterns.

## Before You Start — Is This File Convertible?

Do **NOT** convert the following; leave them in XCTest:

| Pattern | Why |
|---------|-----|
| **ViewInspector tests** | `imports ViewInspector`; requires XCTest infrastructure |
| **Snapshot tests** | Functions named `disabletest_*`, uses `assertSnapshot` or `SnapshotTesting`; depends on `BitwardenTestCase` |
| **UI automation tests** | Uses `XCUIApplication` |
| **Performance tests** | Uses `measure { ... }` or `XCTMetric` |
| **Objective-C tests** | Cannot use Swift Testing |

Stop and flag the issue before proceeding.

## Step 1: Read the File

Read the entire test file first. Understand:
- What type is under test (processor, coordinator, service, etc.)
- Whether any methods have `@MainActor` (and which)
- Whether any tests use `addTeardownBlock`
- Any non-mechanical patterns that may need judgment calls

## Step 2: Transform the File Header

### Imports

Replace `import XCTest` with `import Testing`. Keep all other imports unchanged:

```swift
// Before:
import XCTest
@testable import BitwardenShared

// After:
import Testing
@testable import BitwardenShared
```

`XCTest` implicitly re-exports `Foundation`, so removing it can cause missing-symbol build errors if the file uses Foundation types directly. If the build fails after conversion, add `import Foundation`.

### Class → Struct

| Before | After |
|--------|-------|
| `class FooTests: BitwardenTestCase {` | `struct FooTests {` |
| `final class FooTests: BitwardenTestCase {` | `struct FooTests {` |

### `@MainActor` placement

If test methods had `@MainActor` (processor tests, coordinator tests), move it to the **struct declaration**:

```swift
// Before: @MainActor on individual methods
// After:
@MainActor
struct FooProcessorTests {
```

Service tests typically do not need `@MainActor` — do NOT add it unless the service dispatches to main.

## Step 3: Convert Properties

Change `var ... !` optional properties to `let` non-optionals:

```swift
// Before:
var coordinator: MockCoordinator<FooRoute, FooEvent>!
var errorReporter: MockErrorReporter!
var subject: FooProcessor!

// After:
let coordinator: MockCoordinator<FooRoute, FooEvent>
let errorReporter: MockErrorReporter
let subject: FooProcessor
```

**`services` property**: Remove it if it is only used inside `setUp()` to construct the subject — it does not need to be a stored property in Swift Testing. Keep it as `let services: MockServiceContainer` if test methods reference it directly for assertions.

## Step 4: Convert Setup & Teardown

### `setUp()` → `init()`

Move all setup code into `init()`, removing the `super.setUp()` call:

```swift
// Before:
override func setUp() {
    super.setUp()

    coordinator = MockCoordinator()
    errorReporter = MockErrorReporter()
    subject = FooProcessor(
        coordinator: coordinator.asAnyCoordinator(),
        services: ServiceContainer.withMocks(errorReporter: errorReporter),
        state: FooState(),
    )
}

// After:
init() {
    coordinator = MockCoordinator()
    errorReporter = MockErrorReporter()
    subject = FooProcessor(
        coordinator: coordinator.asAnyCoordinator(),
        services: ServiceContainer.withMocks(errorReporter: errorReporter),
        state: FooState(),
    )
}
```

### `tearDown()` → delete

Remove the entire `tearDown()` override. Swift Testing creates a fresh struct instance for every test — all properties are discarded automatically. No nilling out is needed.

### `addTeardownBlock { ... }`

- If the block just nils out properties: **delete it** (struct isolation handles this).
- If the block cleans up external resources (e.g., temp files, keychain entries): convert to `deinit` and change the struct to a `class`. `deinit` is not available on `struct`.

## Step 5: Convert Test Methods

### Rename and annotate

Remove the `test_` prefix. Add `@Test` attribute. Remove `@MainActor` from individual methods (it's now on the struct):

```swift
// Before:
@MainActor
func test_receive_valueChanged_updatesState() { ... }

// After:
@Test
func receive_valueChanged_updatesState() { ... }
```

`async throws` signatures are unchanged:

```swift
// Before:
@MainActor
func test_perform_appeared_loadsData() async throws { ... }

// After:
@Test
func perform_appeared_loadsData() async throws { ... }
```

## Step 6: Convert Assertions

Use the assertion conversion table in `references/swift-testing-playbook.md` (Section 2) for standard `XCTAssert*` → `#expect`/`#require` substitutions.

One additional Bitwarden-specific conversion not in the playbook:

| XCTest | Swift Testing |
|--------|---------------|
| `assertAsyncThrows(error: e) { try await expr }` | `await #expect(throws: e) { try await expr }` |

Also note: `try XCTUnwrap(a, "msg")` → `try #require(a)` — drop the message, the macro output is self-explanatory.

## Step 7: Bitwarden-Specific Patterns

### Unchanged patterns

These work identically in both frameworks — do not modify them:

- `coordinator.asAnyCoordinator()`
- `ServiceContainer.withMocks(...)`
- `BitwardenTestError.example` / `.mock("desc")`
- `coordinator.alertShown`, `coordinator.routes`
- `errorReporter.errors`

### Cast assertions

```swift
// Before:
XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)

// After:
#expect(errorReporter.errors.last as? BitwardenTestError == .example)
```

### `coordinator.alertShown` nil check

```swift
// Before:
XCTAssertNotNil(coordinator.alertShown.last)

// After:
#expect(coordinator.alertShown.last != nil)
```

### Optional unwrap then assert

```swift
// Before:
let action = try XCTUnwrap(stackNavigator.actions.last)
XCTAssertEqual(action.type, .pushed)

// After:
let action = try #require(stackNavigator.actions.last)
#expect(action.type == .pushed)
```

## Step 8: Verify

Run these checks after conversion:

1. **No XCTest remnants**: grep for `XCTAssert`, `setUp`, `tearDown`, `XCTestCase`, `import XCTest` — all should be gone.
2. **All tests annotated**: every former `test_` function has `@Test`.
3. **No forced optionals**: no `var ... !` properties remain.
4. **Build passes**: run `mint run swiftformat .` and build the target.
5. **Tests pass**: run the converted test file.

## Reference Material

Before proceeding, read:
- `references/swift-testing-playbook.md` — migration cheat sheet, assertion conversions, framework overview
