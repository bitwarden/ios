---
name: fixing-flaky-tests
description: >
  Diagnose and fix flaky (intermittently failing) tests in Bitwarden iOS. Finds the root cause of
  non-deterministic test failures (race conditions, timing issues, shared state, order dependence),
  applies a targeted fix, then stress-tests the fix by running the test 100 times to confirm
  stability. Use this skill whenever a test is failing intermittently, sometimes passes / sometimes
  fails, or someone describes a test as flaky, unstable, or non-deterministic — even if the exact
  cause is unknown. Trigger phrases: "fix flaky test", "test is flaky", "test keeps failing",
  "intermittent failure", "test is non-deterministic", "test fails sometimes", "test randomly fails".
---

# Fixing Flaky Tests — Bitwarden iOS

A flaky test passes sometimes and fails other times without any code change. Flakiness usually
comes from a small set of root causes. Your job is to find which one applies, fix it surgically,
and then prove the fix holds by running the test many times.

## Step 1: Locate the test(s)

Search for the function name(s) the user provided:

```bash
grep -r "func <testFunctionName>" . --include="*.swift" -l
```

Note that:
- **XCTest** functions are named `test_<methodName>_<description>` (prefix required by XCTest)
- **Swift Testing** functions use the `@Test` macro and can have any name — the `test_` prefix is
  conventional but not required

For each test:
- Read the full test function and the class it belongs to
- Read the `@testable import` at the top of the file — that's the module under test
  (e.g., `@testable import BitwardenShared` → module `BitwardenShared`)
- Read the SUT code being exercised by the test

## Step 2: Map the test to a scheme and test plan

| Test target | Scheme | Unit test plan |
|---|---|---|
| `BitwardenSharedTests`, `BitwardenTests`, `BitwardenAutoFillExtensionTests`, `BitwardenActionExtensionTests`, `BitwardenShareExtensionTests` | `Bitwarden` | `Bitwarden-Unit` |
| `AuthenticatorSharedTests`, `AuthenticatorTests`, `AuthenticatorBridgeKitTests` | `Authenticator` | `Authenticator-Unit` |
| `BitwardenKitTests` | `BitwardenKit` | `BitwardenKit-Unit` |
| `BitwardenKitViewInspectorTests` | `BitwardenKit` | `BitwardenKit-ViewInspector` |
| `NetworkingTests` | `BitwardenKit` | `BitwardenKit-Default` |

When in doubt, search `TestPlans/` for the test class name to confirm the plan (and therefore scheme):

```bash
grep -r "<TestClassName>" TestPlans/ -l
```

Always read the simulator config from the project files rather than hardcoding:

```bash
DEVICE=$(tr -d '\n' < .test-simulator-device-name)
OS=$(tr -d '\n' < .test-simulator-ios-version)
```

## Step 3: Diagnose the root cause

Read the test carefully and the SUT it exercises. Flaky tests in Swift/iOS typically fall into one
of these categories:

**Race condition / async ordering**
The test observes a side effect before the async SUT has finished producing it. Signs: bare
`Task.sleep` or `DispatchQueue.asyncAfter` in the test, expectations that time out occasionally,
`@MainActor`-isolated code whose scheduling the test doesn't account for.

**Shared mutable state**
State from one test bleeds into the next. Signs: static properties or singletons not reset in
`tearDown`, `NotificationCenter` observers not removed, `Task` or `DispatchQueue.async` work
from a previous test still running when the next one starts.

**Time / date dependence**
The SUT reads `Date()` or `Calendar.current` inline, so the test result depends on the real clock.
Signs: test passes during the day but fails near midnight, or fails only under heavy load when
wall-clock timing drifts.

**Order dependence**
Test execution order is randomized in the -Default test plans ("testExecutionOrdering" : "random"), but the -Unit plans used for verification here run sequentially. To reproduce order-dependent flakiness, run against the -Default plan rather than -Unit.

**Resource contention**
CoreData, Keychain, or file system state left behind by a previous run.

## Step 4: Fix the test (or plan the SUT change)

### Fixes in the test file only — apply and move on

**Replacing bare delays with condition polling:**
Use the project's test helpers instead of a fixed sleep. These are available to all test targets:

- **XCTest** (subclasses of `BaseBitwardenTestCase`):
  - `waitFor { condition }` — spins the run loop; use when the SUT uses `Timer.scheduledTimer`
  - `waitForAsync { condition }` — polls asynchronously; use for Swift Concurrency-based SUT code

- **Swift Testing** (`SwiftTestingHelpers.swift`):
  - `try await waitForAsync { condition }` — polls asynchronously in `@Test` functions
  - `waitFor(condition)` — spins the run loop in `@Test` functions using `@MainActor`
  - `await withContinuationTimeout { resume in … }` — wraps callback-based async code so the
    test fails cleanly rather than hanging if the callback is never called

**Shared state:**
- Move subject and dependency properties from `static var` to instance `var`
- Reset all mutable properties in `tearDown` / `addTeardownBlock`
- Remove `NotificationCenter` observers: `addTeardownBlock { NotificationCenter.default.removeObserver(token) }`

**CoreData / Keychain leaks:**
- Use `.memory` store type when constructing `AuthenticatorBridgeDataStore` or any CoreData
  stack in tests so nothing persists to disk between runs

### If the fix requires changing the SUT (production code)

Stop before touching production code. Present the plan:
1. The root cause
2. The specific SUT file, line, and change (what pattern to replace with what)
3. Why a test-only fix is insufficient

Then ask: *"Would you like me to proceed, or would you prefer to handle the SUT change
separately?"*

The most common SUT fix is replacing an inline `Date()` or `Calendar.current` call with an
injected `TimeProvider` (protocol in `BitwardenKit/Core/Platform/Services/TimeProvider.swift`),
then using `MockTimeProvider` in the test.

Only proceed with SUT edits after the user agrees.

## Step 5: Verify the fix — run the test 100 times

Build first so the changes are compiled:

```bash
xcodebuild build-for-testing \
  -workspace Bitwarden.xcworkspace \
  -scheme <SCHEME> \
  -destination "platform=iOS Simulator,name=$DEVICE,OS=$OS" \
  2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Then stress-test the fixed test using `-test-iterations`, which runs N repetitions in a single
simulator session (far faster than re-launching xcodebuild 100 times):

```bash
xcodebuild test-without-building \
  -workspace Bitwarden.xcworkspace \
  -scheme <SCHEME> \
  -only-testing:"<TARGET_NAME>/<TestClassName>/<testFunctionName>" \
  -test-iterations 100 \
  -test-repetition-mode count-up \
  -destination "platform=iOS Simulator,name=$DEVICE,OS=$OS" \
  2>&1 | grep -E "(Test Case|Executed|error:|FAILED)" | tail -20
```

`<TARGET_NAME>` is the test bundle (e.g., `BitwardenSharedTests`), `<TestClassName>` is the
class (e.g., `MyProcessorTests`), and `<testFunctionName>` is the Swift function name exactly
as written.

**Interpreting results:**
- `Executed 100 tests, with 0 failures` → fix holds, proceed to Step 6
- Any failure → return to Step 3; the root cause wasn't fully addressed

## Step 6: Run the full unit test suite (once)

Confirm the fix didn't accidentally break anything else in the same target:

```bash
xcodebuild test \
  -workspace Bitwarden.xcworkspace \
  -scheme <SCHEME> \
  -testPlan <SCHEME>-Unit \
  -destination "platform=iOS Simulator,name=$DEVICE,OS=$OS" \
  2>&1 | grep -E "(Test Suite|error:|FAILED|Executed)" | tail -30
```

The `<SCHEME>-Unit` plan (e.g., `Bitwarden-Unit`) excludes snapshot and ViewInspector tests,
keeping the run fast and focused on correctness. If any other test fails, investigate whether the
fix introduced a regression before proceeding.

## Step 7: Final verification — run the build-test-verify skill

As the last step, invoke the `build-test-verify` skill to confirm the full pipeline is clean
(lint, formatter, spell check):

```
Skill: build-test-verify
```

---

## Quick reference

| Symptom | Likely cause | Fix |
|---|---|---|
| Bare `try await Task.sleep(…)` after triggering async SUT | Side effect races the sleep | Replace with `waitForAsync { … }` |
| `Timer.scheduledTimer` result observed immediately | Run loop not spinning | Use `waitFor { … }` (spins run loop) |
| Callback never called → hang | Missing continuation timeout | Use `withContinuationTimeout { resume in … }` |
| `static var` on subject or dependency | Shared state across tests | Move to instance `var`, reset in `tearDown` |
| `NotificationCenter.addObserver` without `removeObserver` | Observer leaks | `addTeardownBlock { NotificationCenter.default.removeObserver(token) }` |
| `Date()` / `Calendar.current` inline in SUT | Wall-clock dependence | Inject `TimeProvider`; use `MockTimeProvider` in tests |
| `waitForExpectations(timeout: 0.1)` | Timeout too tight under load | Increase timeout or replace with `waitForAsync` |
| CoreData state persists across tests | Disk-backed store in tests | Use `.memory` store type |
