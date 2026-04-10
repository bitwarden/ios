# Processor Test Example (Swift Testing)

Based on: `AuthenticatorShared/UI/Platform/Application/AppCoordinatorTests.swift` and processor patterns

```swift
import BitwardenKit
import BitwardenKitMocks
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - FeatureProcessorTests

@MainActor
struct FeatureProcessorTests {
    // MARK: Properties

    let coordinator: MockCoordinator<FeatureRoute, FeatureEvent>
    let errorReporter: MockErrorReporter
    let featureService: MockFeatureService
    let subject: FeatureProcessor

    // MARK: Initialization

    init() {
        coordinator = MockCoordinator<FeatureRoute, FeatureEvent>()
        errorReporter = MockErrorReporter()
        featureService = MockFeatureService()
        let services = ServiceContainer.withMocks(
            errorReporter: errorReporter,
            featureService: featureService,
        )
        subject = FeatureProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: FeatureState(),
        )
    }

    // MARK: Tests

    // MARK: receive(_:) — Action tests (synchronous state mutations)

    /// `receive(.valueChanged)` updates state with the new value.
    @Test
    func receive_valueChanged_updatesState() {
        subject.receive(.valueChanged("new value"))

        #expect(subject.state.value == "new value")
    }

    // MARK: perform(_:) — Effect tests (async work)

    /// `perform(.appeared)` loads data and updates state on success.
    @Test
    func perform_appeared_loadsData() async {
        featureService.fetchItemsResult = .success([.fixture()])

        await subject.perform(.appeared)

        #expect(subject.state.items.count == 1)
        #expect(subject.state.isLoading == false)
    }

    /// `perform(.appeared)` shows an error alert when the service fails.
    @Test
    func perform_appeared_serviceError_showsAlert() async {
        featureService.fetchItemsResult = .failure(BitwardenTestError.example)

        await subject.perform(.appeared)

        #expect(coordinator.alertShown.last != nil)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
    }

    /// `perform(.submitTapped)` navigates on success.
    @Test
    func perform_submitTapped_navigatesOnSuccess() async {
        featureService.submitResult = .success(())

        await subject.perform(.submitTapped)

        #expect(coordinator.routes.last == .nextScreen)
    }
}
```

## Key Patterns

- `struct` with `init()` — no teardown needed, each test gets a fresh instance
- `@MainActor` on the struct — all tests inherit main actor isolation
- `@Test` attribute — replaces `test_` prefix naming convention
- `#expect()` — replaces `XCTAssert*` family; uses inline expressions
- `let` properties — immutable references (no `!` force-unwrap needed)
- `ServiceContainer.withMocks(...)` — same mock injection pattern as XCTest
- `coordinator.asAnyCoordinator()` — same type-erased coordinator pattern
- `BitwardenTestError.example` — same standard test error fixture
- Test both happy path AND error path for every effect
