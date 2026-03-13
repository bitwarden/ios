# Processor Test Example

Based on: `BitwardenShared/UI/Auth/Landing/LandingProcessorTests.swift`

```swift
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - FeatureProcessorTests

class FeatureProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<FeatureRoute, FeatureEvent>!
    var errorReporter: MockErrorReporter!
    var featureService: MockFeatureService!
    var services: MockServiceContainer!
    var subject: FeatureProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<FeatureRoute, FeatureEvent>()
        errorReporter = MockErrorReporter()
        featureService = MockFeatureService()
        services = ServiceContainer.withMocks(
            errorReporter: errorReporter,
            featureService: featureService,
        )
        subject = FeatureProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: FeatureState(),
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        featureService = nil
        services = nil
        subject = nil
    }

    // MARK: Tests

    // MARK: receive(_:) — Action tests (synchronous state mutations)

    /// `receive(.valueChanged)` updates state with the new value.
    @MainActor
    func test_receive_valueChanged_updatesState() {
        subject.receive(.valueChanged("new value"))

        XCTAssertEqual(subject.state.value, "new value")
    }

    // MARK: perform(_:) — Effect tests (async work)

    /// `perform(.appeared)` loads data and updates state on success.
    @MainActor
    func test_perform_appeared_loadsData() async {
        featureService.fetchItemsResult = .success([.fixture()])

        await subject.perform(.appeared)

        XCTAssertEqual(subject.state.items.count, 1)
        XCTAssertFalse(subject.state.isLoading)
    }

    /// `perform(.appeared)` shows an error alert when the service fails.
    @MainActor
    func test_perform_appeared_serviceError_showsAlert() async {
        featureService.fetchItemsResult = .failure(BitwardenTestError.example)

        await subject.perform(.appeared)

        XCTAssertNotNil(coordinator.alertShown.last)
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `perform(.submitTapped)` navigates on success.
    @MainActor
    func test_perform_submitTapped_navigatesOnSuccess() async {
        featureService.submitResult = .success(())

        await subject.perform(.submitTapped)

        XCTAssertEqual(coordinator.routes.last, .nextScreen)
    }
}
```

## Key Patterns

- Subclass `BitwardenTestCase` (not `XCTestCase`)
- `MockCoordinator<Route, Event>` — always pass `coordinator.asAnyCoordinator()` to subject
- `ServiceContainer.withMocks(...)` — inject only the mocks you need to configure
- `@MainActor` on all async test methods
- Test both happy path AND error path for every effect
- `coordinator.alertShown` — array of alerts shown via `coordinator.showErrorAlert`
- `coordinator.routes` — array of navigation routes pushed
- `BitwardenTestError.example` — use for generic test errors
