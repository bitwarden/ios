import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

class PremiumUpgradeProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var billingAPIService: MockBillingAPIService!
    var coordinator: MockCoordinator<PremiumUpgradeRoute, Void>!
    var errorReporter: MockErrorReporter!
    var subject: PremiumUpgradeProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        billingAPIService = MockBillingAPIService()
        coordinator = MockCoordinator<PremiumUpgradeRoute, Void>()
        errorReporter = MockErrorReporter()
        let services = ServiceContainer.withMocks(
            billingAPIService: billingAPIService,
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

        billingAPIService = nil
        coordinator = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.upgradeNowTapped` sets the checkout URL on success.
    @MainActor
    func test_perform_upgradeNowTapped_success() async throws {
        let expectedURL = URL(string: "https://checkout.stripe.com/session")!
        billingAPIService.createCheckoutSessionReturnValue = CheckoutSessionResponseModel(
            checkoutSessionUrl: expectedURL,
        )

        await subject.perform(.upgradeNowTapped)

        XCTAssertEqual(billingAPIService.createCheckoutSessionCallsCount, 1)
        XCTAssertEqual(subject.state.checkoutURL, expectedURL)
        XCTAssertFalse(subject.state.isLoading)
    }

    /// `perform(_:)` with `.upgradeNowTapped` logs the error and shows an error alert on failure.
    @MainActor
    func test_perform_upgradeNowTapped_failure() async throws {
        billingAPIService.createCheckoutSessionThrowableError = BitwardenTestError.example

        await subject.perform(.upgradeNowTapped)

        XCTAssertEqual(billingAPIService.createCheckoutSessionCallsCount, 1)
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
}
