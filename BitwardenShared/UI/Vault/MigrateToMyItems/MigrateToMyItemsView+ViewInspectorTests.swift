// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import XCTest

@testable import BitwardenShared

class MigrateToMyItemsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<MigrateToMyItemsState, MigrateToMyItemsAction, MigrateToMyItemsEffect>!
    var subject: MigrateToMyItemsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: MigrateToMyItemsState(organizationName: "Acme Corporation"))
        let store = Store(processor: processor)

        subject = MigrateToMyItemsView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests - Transfer Page

    /// Tapping the accept button dispatches the `.acceptTransferTapped` effect.
    @MainActor
    func test_acceptButton_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.accept)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .acceptTransferTapped)
    }

    /// Tapping the decline and leave button dispatches the `.declineAndLeaveTapped` action.
    @MainActor
    func test_declineAndLeaveButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.declineAndLeave)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .declineAndLeaveTapped)
    }

    // MARK: Tests - Decline Confirmation Page

    /// Tapping the back button dispatches the `.backTapped` action.
    @MainActor
    func test_backButton_tap() throws {
        processor.state.page = .declineConfirmation
        let button = try subject.inspect().find(viewWithAccessibilityIdentifier: "BackButton").button()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .backTapped)
    }

    /// Tapping the leave organization button dispatches the `.leaveOrganizationTapped` effect.
    @MainActor
    func test_leaveOrganizationButton_tap() async throws {
        processor.state.page = .declineConfirmation
        let button = try subject.inspect().find(
            asyncButton: Localizations.leaveX(processor.state.organizationName),
        )
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .leaveOrganizationTapped)
    }
}
