// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - PremiumPlanViewTests

class PremiumPlanViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<PremiumPlanState, PremiumPlanAction, PremiumPlanEffect>!
    var subject: PremiumPlanView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: PremiumPlanState())
        let store = Store(processor: processor)
        subject = PremiumPlanView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// The billing amount text is visible when status is `.active`.
    @MainActor
    func test_billingAmount_visible_whenActive() throws {
        processor.state.planStatus = .active
        processor.state.subscription = PremiumSubscription(
            cadence: .monthly,
            cancelAt: nil,
            canceled: nil,
            discount: 0,
            estimatedTax: 0,
            gracePeriod: nil,
            nextCharge: nil,
            seatsCost: Decimal(string: "1.65")!,
            status: .active,
            storageCost: 0,
            suspension: nil,
        )
        let billingAmount = processor.state.billingAmount
        let text = try subject.inspect().find(text: billingAmount)
        XCTAssertNotNil(text)
    }

    /// The billing amount text is hidden when status is `.canceled`.
    @MainActor
    func test_billingSection_hidden_whenCanceled() throws {
        processor.state.planStatus = .canceled
        XCTAssertThrowsError(try subject.inspect().find(text: Localizations.billingAmount))
    }

    /// The cancel premium button is hidden when status is `.canceled`.
    @MainActor
    func test_cancelPremiumButton_hidden_whenCanceled() throws {
        processor.state.planStatus = .canceled
        XCTAssertThrowsError(try subject.inspect().find(button: Localizations.cancelPremium))
    }

    /// Tapping the cancel premium button dispatches the `.cancelPremiumTapped` action.
    @MainActor
    func test_cancelPremiumButton_tap() throws {
        processor.state.planStatus = .active
        let button = try subject.inspect().find(button: Localizations.cancelPremium)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .cancelPremiumTapped)
    }

    /// The cancel premium button is visible when status is `.active`.
    @MainActor
    func test_cancelPremiumButton_visible_whenActive() throws {
        processor.state.planStatus = .active
        let button = try subject.inspect().find(button: Localizations.cancelPremium)
        XCTAssertNotNil(button)
    }

    /// Tapping the manage plan button dispatches the `.managePlanTapped` effect.
    @MainActor
    func test_managePlanButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.managePlan)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .managePlanTapped)
    }
}
