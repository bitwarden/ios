---
name: testing-ios-code
description: Write tests, add test coverage, unit test, or add missing tests for Bitwarden iOS. Use when asked to "write tests", "add test coverage", "test this", "unit test", "add tests for", "missing tests", or when creating test files for new implementations.
---

# Testing iOS Code

Use this skill to write tests following Bitwarden iOS patterns.

## Prerequisites

Read `Docs/Testing.md` — it is the authoritative source for test structure, naming, templates, decision matrix, and simulator configuration.

## Step 1: Choose Framework

| Scenario | Framework | Why |
|----------|-----------|-----|
| **New test file** | Swift Testing | Preferred for all new tests |
| **Existing XCTest file** | XCTest | Don't mix frameworks in one file |
| **ViewInspector tests** | XCTest | ViewInspector requires XCTest |
| **Snapshot tests** | XCTest | SnapshotTesting requires `BitwardenTestCase` |

## Step 2: Determine Test Type

Choose the right test type based on what you're testing:

| What | Test type | XCTest example | Swift Testing example |
|------|-----------|----------------|----------------------|
| Processor actions/effects/state | Unit test | `examples/processor-test-example.md` | `examples/processor-test-swift-testing-example.md` |
| Coordinator navigation/routes | Unit test | `examples/coordinator-test-example.md` | `examples/coordinator-test-swift-testing-example.md` |
| View interactions (buttons, toggles) | ViewInspector test | `examples/view-test-example.md` | — (use XCTest) |
| View appearance | Snapshot test (`disabletest_` prefix) | `examples/view-test-example.md` | — (use XCTest) |
| Service/repository business logic | Unit test | `examples/service-test-example.md` | `examples/service-test-swift-testing-example.md` |

## Step 3: Test Setup Pattern

### Swift Testing (new files)

Use a `struct` with `init()` — no teardown needed, value types are discarded after each test:

```swift
@MainActor
struct FeatureProcessorTests {
    let coordinator: MockCoordinator<FeatureRoute, FeatureEvent>
    let services: MockServiceContainer
    let subject: FeatureProcessor

    init() {
        coordinator = MockCoordinator()
        services = ServiceContainer.withMocks()
        subject = FeatureProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: FeatureState(),
        )
    }
}
```

### XCTest (existing files, ViewInspector, snapshots)

Use a `class` subclassing `BitwardenTestCase` with `setUp()`/`tearDown()`:

```swift
class FeatureProcessorTests: BitwardenTestCase {
    var coordinator: MockCoordinator<FeatureRoute, FeatureEvent>!
    var services: MockServiceContainer!
    var subject: FeatureProcessor!

    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        services = ServiceContainer.withMocks()
        subject = FeatureProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: FeatureState(),
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        services = nil
        subject = nil
    }
}
```

See `examples/` for complete patterns per test type.

## Step 4: Write Tests

### Naming

| Framework | Pattern | Example |
|-----------|---------|---------|
| Swift Testing | `@Test func <functionName>_<behavior>()` | `@Test func perform_appeared_loadsData() async` |
| XCTest | `func test_<functionName>_<behavior>()` | `func test_perform_appeared_loadsData() async` |

### Assertions

| XCTest | Swift Testing |
|--------|---------------|
| `XCTAssertEqual(a, b)` | `#expect(a == b)` |
| `XCTAssertTrue(x)` | `#expect(x == true)` or `#expect(x)` |
| `XCTAssertNil(x)` | `#expect(x == nil)` |
| `XCTAssertNotNil(x)` | `#expect(x != nil)` |
| `XCTUnwrap(x)` | `try #require(x)` |
| `XCTAssertThrowsError` | `#expect(throws:) { ... }` |

### Test focus areas

**Processor tests** — test both paths:
- `receive(_:)` actions: assert `subject.state` mutations
- `perform(_:)` effects: `await subject.perform(.effect)`, then assert state or coordinator calls
- Always test error paths, not just happy path

**Service tests** — test:
- Successful operations
- Error handling and propagation
- Interactions with mocked dependencies

**View tests** — test (XCTest only):
- Button taps → `processor.dispatchedActions.last` (sync)
- Async button taps → `processor.effects.last`
- State-driven UI (disabled buttons, text content)

## Step 5: Verify Co-location

Test files must live alongside implementation files:
```
BitwardenShared/UI/Auth/Login/LoginProcessor.swift
BitwardenShared/UI/Auth/Login/LoginProcessorTests.swift  ← same directory
```

## Step 6: Mock Generation

New protocols need mocks:
1. Add `// sourcery: AutoMockable` as a trailing comment on the protocol declaration line
2. Run `mint run sourcery --config BitwardenShared/Sourcery/sourcery.yml`
3. Or just build — Sourcery runs automatically in pre-build phase

See `references/mock-generation.md` for full details.
