import XCTest

@testable import BitwardenShared

// MARK: - VaultListItemRowViewTests

class VaultListItemRowViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultListItemRowState, VaultListItemRowAction, VaultListItemRowEffect>!
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

    func test_moreButton_tap() async throws {
        let button = try subject.inspect().find(asyncButtonWithAccessibilityLabel: Localizations.more)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .morePressed)
    }

    func test_totp_copyButton_tap() throws {
        let totp = VaultListTOTP.fixture()
        processor.state = VaultListItemRowState(
            item: .fixtureTOTP(
                totp: totp
            ),
            hasDivider: false
        )
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.copyTotp)
        let task = Task {
            try button.tap()
        }
        waitFor(!processor.dispatchedActions.isEmpty)
        task.cancel()
        XCTAssertEqual(processor.dispatchedActions.last, .copyTOTPCode(totp.totpCode.code))
    }
}
