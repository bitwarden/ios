---
name: converting-mocks-to-automockable
description: Convert a hand-written bespoke mock to a Sourcery AutoMockable-generated mock. Use this skill whenever the user says "convert this mock", "migrate mock to AutoMockable", "replace bespoke mock", "use Sourcery for this mock", or mentions wanting to convert a Mock*.swift file to use `// sourcery: AutoMockable`. Also use this skill proactively when you notice a new protocol being created without the annotation, or when an existing bespoke mock is being modified and AutoMockable would be sufficient.
---

# Converting Bespoke Mocks to AutoMockable

This skill guides you through assessing whether a hand-written mock can be replaced with a Sourcery-generated one, performing the migration, and updating affected tests.

## Step 1: Assess the Candidate

Read the bespoke mock file and locate its corresponding protocol. Scan for
these disqualifying patterns — if any are present, keep the mock as bespoke:

| Pattern                                                                                    | Why it can't be auto-generated                                                        |
| ------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------- |
| Mock executes passed-in closure parameters (e.g., runs a `() async throws -> T` argument) | Closures passed as arguments are non-escaping; Sourcery stubs these with `fatalError` |
| Mock accumulates all calls into a combined array (e.g., `var alerts: [Alert]`)             | AutoMockable stores last call's args, not a merged collection across overloads        |
| Methods with overloaded signatures that share state                                        | Each overload gets a separate mock; shared logic must be bespoke                      |

If none apply, proceed — AutoMockable handles value returns, throws, async
results, and call tracking out of the box.

## Step 2: Annotate the Protocol

Add `// sourcery: AutoMockable` as a **trailing comment on the protocol's opening line**. Do not put it on the line above.

```swift
// Before
protocol FeatureService: AnyObject {

// After
protocol FeatureService: AnyObject { // sourcery: AutoMockable
```

If the protocol already has a comment on that line (e.g., `// sourcery: AutoMockable` is already there), skip this step.

## Step 3: Map the API — Bespoke to Generated

The generated mock's property names follow deterministic patterns. Use this table to translate test code:

| Bespoke pattern                                                                   | Generated equivalent                                                                                                                                     |
| --------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `var fooResult: Result<T, Error> = .success(x)`                                   | `var fooReturnValue: T! = x` (for the value)                                                                                                             |
| `var fooResult: Result<T, Error> = .failure(e)`                                   | `var fooThrowableError: (any Error)? = e`                                                                                                                |
| `var fooCalled: Bool = false`                                                     | `var fooCalled: Bool { fooCallsCount > 0 }` — same name, same semantics, no change needed in tests                                                       |
| `var fooCalledCount: Int = 0`                                                     | `var fooCallsCount = 0` — note the naming difference (`Calls` not `Called`)                                                                              |
| `fooBarCalled = false` (mid-test reset between assertions)                        | `fooBarCallsCount = 0` — `fooCalled` is computed, so it can't be assigned; reset the underlying count instead                                            |
| `var fooHandler: (() -> Void)?` (side-effect hook, no args)                       | `var fooClosure: ((ArgTypes) async throws -> ReturnType)?` — generated closure takes the method's arguments; use `_, _` if the handler doesn't need them |
| `var fooParam: T?` (captures a single named arg, e.g. `foo(name: String)`)        | `var fooReceivedName: (String)?` — uses the **parameter label**, not `ReceivedArguments`                                                                 |
| `var fooParam1: T1?` + `var fooParam2: T2?` (captures multiple args)              | `var fooReceivedArguments: (param1: T1, param2: T2)?` — collapses all args into a labeled tuple                                                          |
| `var fooValue: T = default` (stored property returned by a method named `getBar`) | `var getBarReturnValue: T!` — derives from the **method** name, not the stored property name                                                             |
| Custom closure to inject behavior                                                 | `var fooClosure: ((ArgTypes) -> ReturnType)?`                                                                                                            |

### Stored-property return values

Some bespoke mocks expose a plain stored property that a method simply returns:

```swift
// Bespoke
var fooStatus: FooStatus = .idle

func getFooStatus(_ context: BarContext?) -> FooStatus {
    fooStatus
}
```

Tests write directly to the stored property:

```swift
mockService.fooStatus = .active
```

The generated mock drops the stored property and routes through `ReturnValue` named after the **method**:

```swift
// Generated
var getFooStatusReturnValue: FooStatus!
```

Tests update to:

```swift
mockService.getFooStatusReturnValue = .active
```

The generated property name comes from the **method** (`getFooStatus` + `ReturnValue`), not from the old stored property name (`fooStatus`). They'll often differ — always read the generated output to confirm the exact name rather than guessing from the bespoke property.

### Parameter capture: single vs. multiple

For a method with **one named parameter**, Sourcery generates a property named `{methodName}Received{Label}` — using the parameter's label, not a generic `ReceivedArguments`:

```swift
// Protocol: func doThing(name: String) async throws
// Generated:
var doThingReceivedName: (String)?
```

For a method with **multiple parameters**, Sourcery collapses them into a single labeled tuple named `ReceivedArguments`. Bespoke mocks often spread these across several named properties — update all of them to go through the tuple:

```swift
// Bespoke — separate property per argument
var doThingName: String?
var doThingCount: Int?
var doThingEnabled: Bool?

func doThing(name: String, count: Int, enabled: Bool) async {
    doThingName = name
    doThingCount = count
    doThingEnabled = enabled
}

// Generated — one tuple property, labeled with the parameter names
var doThingReceivedArguments: (name: String, count: Int, enabled: Bool)?
```

```swift
// Before
mockService.doThingName == "hello"
mockService.doThingCount == 3
mockService.doThingEnabled == true

// After
mockService.doThingReceivedArguments?.name == "hello"
mockService.doThingReceivedArguments?.count == 3
mockService.doThingReceivedArguments?.enabled == true
```

Nil checks via optional chaining preserve the original semantics: `mockService.doThingReceivedArguments?.name` is nil both when the method was never called (whole tuple is nil) and when it was called with a nil argument — matching what the bespoke `mockService.doThingName` would have been.

### Throwing methods

```swift
// Bespoke
var fetchFoosResult: Result<[Foo], Error> = .success([])
func fetchFoos() async throws -> [Foo] {
    return try fetchFoosResult.get()
}

// Generated equivalent — two separate properties
mockService.fetchFoosReturnValue = []          // set return value
mockService.fetchFoosThrowableError = someErr  // or set error to throw
```

When both are set, the generated mock checks for `ThrowableError` first and throws it, ignoring `ReturnValue`.

### Void-return throwing methods

```swift
// Bespoke
var deleteFooCalled = false
var deleteFooError: Error?
func deleteFoo() async throws {
    deleteFooCalled = true
    if let error = deleteFooError { throw error }
}

// Generated equivalent
mockService.deleteFooThrowableError = someErr  // nil by default (no throw)
```

### Methods with return values (non-throwing)

```swift
// Bespoke
var isEnabledResult: Bool = false
func isEnabled() -> Bool { isEnabledResult }

// Generated equivalent
mockService.isEnabledReturnValue = false  // note: implicitly unwrapped optional, crashes if not set
```

Always set `ReturnValue` before the test exercises that method — it's `T!`, not `T?`. If you need to vary behavior across calls (e.g. return different values on successive invocations), use `isEnabledClosure` instead.

### Watch out: bespoke defaults vs. generated nil

Bespoke mocks often supply safe default return values (e.g. `var isEnabledResult: Result<Bool, Error> = .success(false)`). Every test that calls through to that method was silently relying on that default. The generated mock starts with `isEnabledReturnValue: Bool!` — `nil` — and will crash at runtime the first time a test exercises that path without setting it first.

**After converting, look for this pattern:** any test in the file that calls the subject under test but does _not_ set `*ReturnValue` for a method that returns a non-optional. Check both:

- The test body itself
- Any shared `setUp()` that might need a default added

**Don't just look at the test files — look at the production code too.** A test might not reference a mock method directly, yet still exercise it indirectly through the subject under test. For each non-optional-returning method on the protocol, search the production implementations of the subjects that use this mock:

```bash
grep -rn "<mockPropertyName>\." <path/to/subject/implementation>
```

If the subject calls any of those methods anywhere in its implementation, every test that exercises that code path will crash without a default. Add the appropriate defaults to `setUp()` to cover the whole suite.

The fix is to set a sensible default in the shared setup, covering all tests that don't care about that method's return value. The pattern differs by test framework:

**XCTest:**

```swift
override func setUp() {
    super.setUp()
    mockService = MockFooService()
    mockService.isEnabledReturnValue = false  // safe default for tests that don't configure it
}
```

**Swift Testing:**

```swift
struct FooTests {
    var mockService: MockFooService

    init() {
        mockService = MockFooService()
        mockService.isEnabledReturnValue = false  // safe default for tests that don't configure it
    }
}
```

Tests that need a specific value override it in their own body as before.

## Step 4: Delete the Bespoke Mock

Remove the bespoke mock:

- If it's a standalone file (`MockFoo.swift`), delete the entire file.
- If it's defined inside another file, remove the class definition.

Check that no other code imports or references the bespoke mock class directly.

After deleting a standalone file, regenerate the Xcode project so the stale file reference is removed — otherwise the build will fail with "Build input file cannot be found":

```bash
# Match to the framework where the mock lived
mint run xcodegen --spec project-pm.yml
mint run xcodegen --spec project-bwa.yml
mint run xcodegen --spec project-bwk.yml
```

## Step 5: Regenerate Mocks

Run Sourcery manually to generate the new mock before updating tests, so you can see exactly what was generated:

```bash
# Match to the framework where the protocol lives
# Requires BUILD_DIR — see the script header for the standalone one-liner
./Scripts/generate-mocks.sh BitwardenShared
./Scripts/generate-mocks.sh BitwardenKit
./Scripts/generate-mocks.sh AuthenticatorShared
./Scripts/generate-mocks.sh AuthenticatorBridgeKit
```

After running, find the new `Mock<ProtocolName>` block in the appropriate `Sourcery/Generated/AutoMockable.generated.swift` and read it to confirm the property names before updating tests.

## Step 6: Update Tests

With the generated mock's actual property names in hand, update each test that used the bespoke mock. Translate according to the mapping in Step 3.

Common things to change:

- Replace `Result`-based setup with `ReturnValue`/`ThrowableError`
- Replace bespoke parameter capture properties with `Received{Label}` (single param) or `ReceivedArguments` tuple (multiple params)

### Adding the import

Generated mocks live in `BitwardenSharedMocks` (or `AuthenticatorSharedMocks`, etc.), not in the test target directly. Any test file that references the generated mock class needs:

```swift
@testable import BitwardenSharedMocks
```

This applies to:

- Test files (`*Tests.swift`) that declare or use the mock
- `TestHelpers/` files that reference the mock class (e.g., factories that return a mock as a fallback)

If you see `cannot find type 'MockFoo' in scope` after deleting a bespoke mock, a missing import is almost always the cause. Check every file that previously had access to the bespoke mock via co-location.

## Step 7: Verify

Format, lint, then run the affected tests:

```bash
mint run swiftformat .
mint run swiftlint
```

Run the affected test suite (read simulator config from the project files):

```bash
DEVICE=$(tr -d '\n' < .test-simulator-device-name)
OS=$(tr -d '\n' < .test-simulator-ios-version)
xcodebuild test \
  -workspace Bitwarden.xcworkspace \
  -scheme Bitwarden \
  -testPlan Bitwarden-Default \
  -only-testing "<TargetTests>/<TestClassName>" \
  -destination "platform=iOS Simulator,name=$DEVICE,OS=$OS"
```

Fix any compile errors or test failures from the API translation.
