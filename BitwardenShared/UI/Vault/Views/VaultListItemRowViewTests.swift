import XCTest

@testable import BitwardenShared

// MARK: - VaultListItemRowViewTests

class VaultListItemRowViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultListItemRowState, VaultListItemRowAction, Void>!
    var subject: VaultListItemRowView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        let state = VaultListItemRowState(item: .fixture(), hasDivider: false)
        processor = MockProcessor(state: state)
        let store = Store(processor: processor)
        subject = VaultListItemRowView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    func test_moreButton_tap() throws {
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.more)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .morePressed)
    }
}
