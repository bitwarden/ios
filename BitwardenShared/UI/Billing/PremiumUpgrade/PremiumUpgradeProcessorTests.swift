import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

class PremiumUpgradeProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var billingService: MockBillingService!
    var coordinator: MockCoordinator<PremiumUpgradeRoute, Void>!
    var errorReporter: MockErrorReporter!
    var subject: PremiumUpgradeProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        billingService = MockBillingService()
        coordinator = MockCoordinator<PremiumUpgradeRoute, Void>()
        errorReporter = MockErrorReporter()
        let services = ServiceContainer.withMocks(
            billingService: billingService,
            errorReporter: errorReporter,
        )
        subject = PremiumUpgradeProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: PremiumUpgradeState(),
        )
    }

    override func tearDown() {
        super.tearDown()

        billingService = nil
        coordinator = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.upgradeNowTapped` sets the checkout URL on success.
    @MainActor
    func test_perform_upgradeNowTapped_success() async throws {
        let expectedURL = URL(string: "https://checkout.stripe.com/session")!
        billingService.createCheckoutSessionReturnValue = expectedURL

        await subject.perform(.upgradeNowTapped)

        XCTAssertEqual(billingService.createCheckoutSessionCallsCount, 1)
        XCTAssertEqual(subject.state.checkoutURL, expectedURL)
        XCTAssertFalse(subject.state.isLoading)
    }

    /// `perform(_:)` with `.upgradeNowTapped` logs the error and shows an error alert on failure.
    @MainActor
    func test_perform_upgradeNowTapped_failure() async throws {
        billingService.createCheckoutSessionThrowableError = BitwardenTestError.example

        await subject.perform(.upgradeNowTapped)

        XCTAssertEqual(billingService.createCheckoutSessionCallsCount, 1)
        XCTAssertNil(subject.state.checkoutURL)
        XCTAssertFalse(subject.state.isLoading)
        XCTAssertEqual(errorReporter.errors.first as? BitwardenTestError, .example)
        XCTAssertEqual(coordinator.errorAlertsShown.count, 1)
    }

    /// `receive(_:)` with `.cancelTapped` navigates to dismiss.
    @MainActor
    func test_receive_cancelTapped() {
        subject.receive(.cancelTapped)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive(_:)` with `.clearURL` clears the checkout URL.
    @MainActor
    func test_receive_clearURL() {
        subject.state.checkoutURL = URL(string: "https://example.com")

        subject.receive(.clearURL)

        XCTAssertNil(subject.state.checkoutURL)
    }

    /// `perform(_:)` with `.upgradeNowTapped` shows an error when the service returns an invalid URL error.
    @MainActor
    func test_perform_upgradeNowTapped_invalidUrl() async throws {
        billingService.createCheckoutSessionThrowableError = BillingError.invalidCheckoutUrl

        await subject.perform(.upgradeNowTapped)

        XCTAssertNil(subject.state.checkoutURL)
        XCTAssertFalse(subject.state.isLoading)
        XCTAssertEqual(errorReporter.errors.first as? BillingError, .invalidCheckoutUrl)
        XCTAssertEqual(coordinator.errorAlertsShown.count, 1)
    }

    /// `receive(_:)` with `.urlOpenFailed` shows an error alert.
    @MainActor
    func test_receive_urlOpenFailed() async throws {
        subject.receive(.urlOpenFailed)

        try await waitForAsync { self.coordinator.errorAlertsShown.count == 1 }
        XCTAssertEqual(coordinator.errorAlertsShown.first as? BillingError, .unableToOpenCheckout)
    }
}
