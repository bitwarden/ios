// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import XCTest

@testable import BitwardenShared

class VaultItemSelectionViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultItemSelectionState, VaultItemSelectionAction, VaultItemSelectionEffect>!
    var subject: VaultItemSelectionView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: VaultItemSelectionState(
            iconBaseURL: nil,
            totpKeyModel: .fixtureExample,
        ))
        let store = Store(processor: processor)

        subject = VaultItemSelectionView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the add item floating action button dispatches the `.addTapped` action.`
    @MainActor
    func test_addFloatingActionButton_tap() async throws {
        let fab = try subject.inspect().find(
            floatingActionButtonWithAccessibilityIdentifier: "AddItemFloatingActionButton",
        )
        try await fab.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addTapped)
    }

    /// Tapping the cancel button dispatches the `.cancelTapped` action.
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().findCancelToolbarButton()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .cancelTapped)
    }

    /// In the empty state, tapping the add item button dispatches the `.addTapped` action.
    @MainActor
    func test_emptyState_addItemTapped() throws {
        let button = try subject.inspect().find(button: Localizations.newItem)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .addTapped)
    }
}
