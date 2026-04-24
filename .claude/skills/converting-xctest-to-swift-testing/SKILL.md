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
| **Tests asserting on alert display** | Uses `coordinator.alertShown`; alert presentation requires `UI.animated = false`, which `BitwardenTestCase.setUp()` sets |
| **Tests asserting on loading overlay display** | Uses `coordinator.loadingOverlaysShown`; same dependency on `UI.animated = false` |

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

Change force-unwrapped `var` properties (those ending in `!`) to `let` non-optionals:

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

## Step 4: Convert Setup, Teardown, and State Lifecycle

Swift Testing replaces `setUpWithError` and `tearDownWithError` with a more natural, type-safe lifecycle using `init()` and `deinit`.

**The Core Concept:** A fresh, new instance of the test suite (`struct` or `class`) is created for **each** test function it contains. This is the cornerstone of test isolation, guaranteeing that state from one test cannot leak into another.

| Method | Replaces... | Behavior |
|---|---|---|
| `init()` | `setUpWithError()` | The initializer for your suite. Put all setup code here. It can be `async` and `throws`. |
| `deinit` | `tearDownWithError()` | The deinitializer. Put cleanup code here. It runs automatically after each test. **Note:** `deinit` is only available on `class` or `actor` suite types, not `struct`s. This is a common reason to choose a class for your suite. |

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

### Action Items
- [ ] Convert test classes from `XCTestCase` to `struct`s (preferred for automatic state isolation) or `final class`es.
- [ ] Move `setUp` logic into the suite's `init()`.
- [ ] Move `tearDown` logic into the suite's `deinit` (and use a `class` or `actor` if needed).
- [ ] Define the SUT and its dependencies as `let` properties, initialized in `init()`.

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

Replace the entire `XCTAssert` family with two powerful, expressive macros. They accept regular Swift expressions, eliminating the need for dozens of specialized `XCTAssert` functions.

| Macro | Use Case & Behavior |
|---|---|
| **`#expect(expression)`** | **Soft Check.** Use for most validations. If the expression is `false`, the issue is recorded, but the test function continues executing. This allows you to find multiple failures in a single run. |
| **`#require(expression)`**| **Hard Check.** Use for critical preconditions (e.g., unwrapping an optional). If the expression is `false` or throws, the test is immediately aborted. This prevents cascading failures from an invalid state. |

### Power Move: Visual Failure Diagnostics
Unlike `XCTAssert`, which often only reports that a comparison failed, `#expect` shows you the exact values that caused the failure, directly in the IDE and logs. This visual feedback is a massive productivity boost.

**Code:**
```swift
@Test("User count meets minimum requirement")
func userCount_minimum() {
    let userCount = 5
    // This check will fail
    #expect(userCount > 10)
}
```

**Failure Output in Xcode:**
```
▽ Expected expression to be true
#expect(userCount > 10)
      |         | |
      5         | 10
                false
```

### Power Move: Optional-Safe Unwrapping
`#require` is the new, safer replacement for `XCTUnwrap`. It not only checks for `nil` but also unwraps the value for subsequent use.

**Before: The XCTest Way**
```swift
// In an XCTestCase subclass...
func testFetchUser_succeeds_XCTest() async throws {
    let user = try XCTUnwrap(await fetchUser(id: "123"), "Fetching user should not return nil")
    XCTAssertEqual(user.id, "123")
}
```

**After: The Swift Testing Way**
```swift
@Test("Fetching a valid user succeeds")
func fetchUser_succeeds() async throws {
    // #require both checks for nil and unwraps `user` in one step.
    // If fetchUser returns nil, the test stops here and fails.
    let user = try #require(await fetchUser(id: "123"))

    // `user` is now a non-optional User, ready for further assertions.
    #expect(user.id == "123")
    #expect(user.age == 37)
}
```

### Common Assertion Conversions Quick Reference

Use this table as a cheat sheet when migrating your `XCTest` assertions.

| XCTest Assertion | Swift Testing Equivalent | Notes |
|---|---|---|
| `XCTAssert(expr)` | `#expect(expr)` | Direct replacement for a boolean expression. |
| `XCTAssertEqual(a, b)` | `#expect(a == b)` | Use the standard `==` operator. |
| `XCTAssertNotEqual(a, b)`| `#expect(a != b)` | Use the standard `!=` operator. |
| `XCTAssertNil(a)` | `#expect(a == nil)` | Direct comparison to `nil`. |
| `XCTAssertNotNil(a)` | `#expect(a != nil)` | Direct comparison to `nil`. |
| `XCTAssertTrue(a)` | `#expect(a)` | No change needed if `a` is already a Bool. |
| `XCTAssertFalse(a)` | `#expect(!a)` | Use the `!` operator to negate the expression. |
| `XCTAssertGreaterThan(a, b)` | `#expect(a > b)` | Use any standard comparison operator: `>`, `<`, `>=`, `<=` |
| `try XCTUnwrap(a)` | `try #require(a)` | The preferred, safer way to unwrap optionals. |
| `try XCTUnwrap(a, "msg")` | `try #require(a)` | drop the message, the macro output is self-explanatory. |
| Basic `XCTAssertThrowsError(expr)` | `#expect(throws: (any Error).self) { try expr }` | The basic form for checking any error. |
| Typed `XCTAssertThrowsError(expr)` | `#expect(throws: BitwardenTestError.self)` | Ensures an error of a specific *type* is thrown. |
| Specific Error `XCTAssertThrowsError(expr)` | `#expect(throws: BitwardenTestError.example)` | Validates a specific error *value* is thrown. Error type must conform to `Equatable`. |
| `XCTAssertNoThrow(try expr)` | `#expect(throws: Never.self) { try expr }` | The explicit way to assert that no error is thrown. |
| `assertAsyncThrows(error: e) { try await expr }` | `await #expect(throws: e) { try await expr }` | Bitwarden-specific helper; note that `await` moves to the front of `#expect` for async closures. |
| `XCTFail("message")` | `Issue.record("message")` | Direct replacement for unconditional test failure. |

### Action Items
- [ ] Run `grep -R "XCTAssert\|XCTUnwrap" .` to find all legacy assertions.
- [ ] Convert `try XCTUnwrap()` calls to `try #require()`. This is a direct and superior replacement.
- [ ] Convert most `XCTAssert...()` calls to `#expect()`. Use `#require()` only for preconditions where continuing the test makes no sense.
- [ ] Group related checks logically within a test. Since `#expect` continues on failure, you can naturally check multiple properties of an object in a single test.

## Step 7: Drastically Reduce Boilerplate with Parameterized Tests

Run a single test function with multiple argument sets to maximize coverage with minimal code. This is superior to a `for-in` loop because each argument set runs as an independent test, can be run in parallel, and failures are reported individually.

| Pattern | How to Use It & When |
|---|---|
| **Single Collection** | `@Test(arguments: [0, 100, -40])` <br> The simplest form. Pass a collection of inputs. |
| **Zipped Collections** | `@Test(arguments: zip(inputs, expectedOutputs))` <br> The most common and powerful pattern. Use `zip` to pair inputs and expected outputs, ensuring a one-to-one correspondence. |
| **Multiple Collections** | `@Test(arguments: ["USD", "EUR"], [1, 10, 100])` <br> **⚠️ Caution: Cartesian Product.** This creates a test case for *every possible combination* of arguments. Use it deliberately when you need to test all combinations. |

### Example: Migrating Repetitive Tests to a Parameterized One

**Before: The XCTest Way**
```swift
func test_flavorVanilla_containsNoNuts() {
    let flavor = Flavor.vanilla
    XCTAssertFalse(flavor.containsNuts)
}
func test_flavorPistachio_containsNuts() {
    let flavor = Flavor.pistachio
    XCTAssertTrue(flavor.containsNuts)
}
func test_flavorChocolate_containsNoNuts() {
    let flavor = Flavor.chocolate
    XCTAssertFalse(flavor.containsNuts)
}
```

**After: The Swift Testing Way using `zip`**
```swift
@Test("Flavor nut content is correct", arguments: zip(
    [Flavor.vanilla, .pistachio, .chocolate],
    [false, true, false]
))
func flavor_containsNuts(flavor: Flavor, expected: Bool) {
    #expect(flavor.containsNuts == expected)
}
```

### Action Items
- [ ] Combine multiple tests with matching boilerplate into a single parameterized test

## Step 8: Bitwarden-Specific Patterns

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

## Step 9: Verify

Run these checks after conversion:

1. **No XCTest remnants**: grep for `XCTAssert`, `setUp`, `tearDown`, `XCTestCase`, `import XCTest` — all should be gone.
2. **All tests annotated**: every former `test_` function has `@Test`.
3. **No forced optionals**: no force-unwrapped `var` properties remain.
4. **Build passes**: run `mint run swiftformat .` and build the target.
5. **Tests pass**: run the converted test file.

## Reference Material

This is additional information about Swift Testing that doesn't neatly fit into steps above.

### Conditional Execution & Skipping

Dynamically control which tests run based on feature flags, environment, or known issues.

| Trait | What It Does & How to Use It |
|---|---|
| **`.disabled("Reason")`** | **Unconditionally skips a test.** The test is not run, but it is still compiled. Always provide a descriptive reason for CI visibility (e.g., `"Flaky on CI, see FB12345"`). |
| **`.enabled(if: condition)`** | **Conditionally runs a test.** The test only runs if the boolean `condition` is `true`. This is perfect for tests tied to feature flags or specific environments. <br> ```swift @Test(.enabled(if: FeatureFlags.isNewAPIEnabled)) func newAPI() { /* ... */ } ``` |
| **`@available(...)`** | **OS Version-Specific Tests.** Apply this attribute directly to the test function. It's better than a runtime `#available` check because it allows the test runner to know the test is skipped for platform reasons, which is cleaner in test reports. |

### Writing Assertions with Standard Swift

Swift Testing's philosophy is to use plain Swift expressions for assertions. For more complex checks like unordered collections or floating-point numbers, use the power of the Swift standard library.

| Assertion Type | How to Write It |
| :--- | :--- |
| **Comparing Collections (Unordered)** | A simple `==` check on arrays fails if elements are the same but the order is different. To check for equality while ignoring order, convert both collections to a `Set`. <br><br> **Brittle:** `#expect(tags == ["ios", "swift"])` // Fails if tags are `["swift", "ios"]` <br> **Robust:** `#expect(Set(tags) == Set(["swift", "ios"]))` // Passes |
| **Floating-Point Accuracy** | Floating-point math is imprecise. `#expect(0.1 + 0.2 == 0.3)` will fail. To ensure tests are robust, check that the absolute difference between the values is within an acceptable tolerance. <br><br> **Fails:** `#expect(result == 0.3)` <br> **Passes:** `#expect(abs(result - 0.3) < 0.0001)` |

### Structure and Organization at Scale

Use suites and tags to manage large and complex test bases.

#### Suites and Nested Suites
A `@Suite` groups related tests and can be nested for a clear hierarchy. Traits applied to a suite are inherited by all tests and nested suites within it.

#### Tags for Cross-Cutting Concerns
Tags associate tests with common characteristics (e.g., `.network`, `.ui`, `.regression`) regardless of their suite. This is invaluable for filtering.

1.  **Define Tags in a Central File:**
    ```swift
    // /Tests/Support/TestTags.swift
    import Testing

    extension Tag {
        @Tag static var fast: Self
        @Tag static var regression: Self
        @Tag static var flaky: Self
        @Tag static var networking: Self
    }
    ```
2.  **Apply Tags & Filter:**
    ```swift
    // Apply to a test or suite
    @Test("Username validation", .tags(.fast, .regression))
    func username_validation() { /* ... */ }

    // Run from CLI
    // swift test --filter .fast
    // swift test --skip .flaky
    // swift test --filter .networking --filter .regression

    // Filter in Xcode Test Plan
    // Add "fast" to the "Include Tags" field or "flaky" to the "Exclude Tags" field.
    ```

#### Power Move: Xcode UI Integration for Tags
Xcode deeply integrates with tags, turning them into a powerful organizational tool.

- **Grouping by Tag in Test Navigator:** In the Test Navigator (`Cmd-6`), click the tag icon at the top. This switches the view from the file hierarchy to one where tests are grouped by their tags. It's a fantastic way to visualize and run all tests related to a specific feature.
- **Test Report Insights:** After a test run, the Test Report can automatically find patterns. Go to the **Insights** tab to see messages like **"All 7 tests with the 'networking' tag failed."** This immediately points you to systemic issues, saving significant debugging time.

### Concurrency and Asynchronous Testing

#### Async/Await and Confirmations
- **Async Tests**: Simply mark your test function `async` and use `await`.
- **Confirmations**: To test APIs with completion handlers or that fire multiple times (like delegates or notifications), use the `confirmation` global function. It wraps the entire asynchronous operation and implicitly waits.

```swift
@Test("Delegate is notified 3 times")
func delegate_notifications() async {
    // The test operation is wrapped in an `await confirmation` call.
    // It will automatically wait or fail if the count isn't met in time.
    await confirmation("delegate.didUpdate was called", expectedCount: 3) { confirm in
        // `confirm` is a function passed to your closure. Call it when the event happens.
        let delegate = MockDelegate {
            confirm() // Call the confirmation
        }
        let sut = SystemUnderTest(delegate: delegate)

        // The action that triggers the events happens *inside* the closure.
        sut.performActionThatNotifiesThreeTimes()
    }
}
```

#### Advanced Asynchronous Patterns

##### Asserting an Event Never Happens
Use a confirmation with `expectedCount: 0` to verify that a callback or delegate method is *never* called during an operation. If `confirm()` is called, the test will fail.

```swift
@Test("Logging out does not trigger a data sync")
func logout_doesNotSync() async {
    await confirmation("data sync was triggered", expectedCount: 0) { confirm in
        let mockSyncEngine = MockSyncEngine {
            // If this is ever called, the test will automatically fail.
            confirm()
        }
        let sut = AccountManager(syncEngine: mockSyncEngine)
    
        sut.logout()
    }
}
```

##### Bridging Legacy Completion Handlers
For older asynchronous code that uses completion handlers, use `withCheckedThrowingContinuation` to wrap it in a modern `async/await` call that Swift Testing can work with.

```swift
func legacyFetch(completion: @escaping (Result<Data, Error>) -> Void) {
    // ... legacy async code ...
}

@Test func legacyFetch() async throws {
    let data = try await withCheckedThrowingContinuation { continuation in
        legacyFetch { result in
            continuation.resume(with: result)
        }
    }
    #expect(!data.isEmpty)
}
```

#### Controlling Parallelism
- **`.serialized`**: Apply this trait to a `@Test` or `@Suite` to force its contents to run serially (one at a time). Use this as a temporary measure for legacy tests that are not thread-safe or have hidden state dependencies. The goal should be to refactor them to run in parallel.
- **`.timeLimit`**: A safety net to prevent hung tests from stalling CI. The more restrictive (shorter) duration wins when applied at both the suite and test level.

### Advanced API Cookbook

| Feature | What it Does & How to Use It |
|---|---|
| **`withKnownIssue`** | Marks a test as an **Expected Failure**. It's better than `.disabled` for known bugs. The test still runs but won't fail the suite. Crucially, if the underlying bug gets fixed and the test *passes*, `withKnownIssue` will fail, alerting you to remove it. |
| **`CustomTestStringConvertible`** | Provides custom, readable descriptions for your types in test failure logs. Conform your key models to this protocol to make debugging much easier. |
| **`.bug(id: "JIRA-123")` Trait** | Associates a test directly with a ticket in your issue tracker. This adds invaluable context to test reports in Xcode and Xcode Cloud. |
| **`Test.current`** | A static property (`Test.current`) that gives you runtime access to the current test's metadata, such as its name, tags, and source location. Useful for advanced custom logging. |
| **Multiple `#expect` Calls** | Unlike XCTest where a failure might stop a test, `#expect` allows execution to continue. You can place multiple `#expect` calls in a single test to validate different properties of an object, and all failures will be reported together. There is no need for a special grouping macro. |

## Appendix: Evergreen Testing Principles (The F.I.R.S.T. Principles)

These foundational principles are framework-agnostic, and Swift Testing is designed to make adhering to them easier than ever.

| Principle | Meaning | Swift Testing Application |
|---|---|---|
| **Fast** | Tests must execute in milliseconds. | Lean on default parallelism. Use `.serialized` sparingly. |
| **Isolated**| Tests must not depend on each other. | Swift Testing enforces this by creating a new suite instance for every test. Random execution order helps surface violations. |
| **Repeatable** | A test must produce the same result every time. | Control all inputs (dates, network responses) with mocks/stubs. Reset state in `init`/`deinit`. |
| **Self-Validating**| The test must automatically report pass or fail. | Use `#expect` and `#require`. Never rely on `print()` for validation. |
| **Timely**| Write tests alongside the production code. | Use parameterized tests (`@Test(arguments:)`) to easily cover edge cases as you write code. |
