---
name: testing-ios-code
description: Write tests, add test coverage, unit test, or add missing tests for Bitwarden iOS. Use when asked to "write tests", "add test coverage", "test this", "unit test", "add tests for", "missing tests", or when creating test files for new implementations.
---

# Testing iOS Code

Use this skill to write tests following Bitwarden iOS patterns.

## Prerequisites

Read `Docs/Testing.md` — it is the authoritative source for test structure, naming, templates, decision matrix, and simulator configuration.

## Step 1: Determine Test Type

Choose the right test type based on what you're testing:

| What | Test type | Example file |
|------|-----------|--------------|
| Processor actions/effects/state | Unit test (`BitwardenTestCase`) | `examples/processor-test-example.md` |
| Coordinator navigation/routes | Unit test (`BitwardenTestCase`) | `examples/coordinator-test-example.md` |
| View interactions (buttons, toggles) | ViewInspector test | `examples/view-test-example.md` |
| View appearance | Snapshot test (`disabletest_` prefix) | `examples/view-test-example.md` |
| Service/repository business logic | Unit test | `examples/service-test-example.md` |

## Step 2: Test Setup Pattern

All processor and coordinator tests use `ServiceContainer.withMocks(...)`:

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

## Step 3: Write Tests

**Naming**: `test_<functionName>_<behaviorDescription>`

**Processor tests** — test both paths:
- `receive(_:)` actions: assert `subject.state` mutations
- `perform(_:)` effects: `await subject.perform(.effect)`, then assert state or coordinator calls
- Always test error paths, not just happy path

**Service tests** — test:
- Successful operations
- Error handling and propagation
- Interactions with mocked dependencies

**View tests** — test:
- Button taps → `processor.dispatchedActions.last` (sync)
- Async button taps → `processor.effects.last`
- State-driven UI (disabled buttons, text content)

## Step 4: Verify Co-location

Test files must live alongside implementation files:
```
BitwardenShared/UI/Auth/Login/LoginProcessor.swift
BitwardenShared/UI/Auth/Login/LoginProcessorTests.swift  ← same directory
```

## Step 5: Mock Generation

New protocols need mocks:
1. Add `// sourcery: AutoMockable` above the protocol
2. Run `mint run sourcery --config BitwardenShared/Sourcery/sourcery.yml`
3. Or just build — Sourcery runs automatically in pre-build phase

See `references/mock-generation.md` for full details.
