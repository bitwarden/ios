import SnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - VaultListItemRowViewTests

class VaultListItemRowViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultListItemRowState, VaultListItemRowAction, VaultListItemRowEffect>!
    var subject: VaultListItemRowView!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        let state = VaultListItemRowState(item: .fixture(), hasDivider: false, showWebIcons: true)
        processor = MockProcessor(state: state)
        let store = Store(processor: processor)
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2023, month: 12, day: 31)))
        subject = VaultListItemRowView(store: store, timeProvider: timeProvider)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
        timeProvider = nil
    }

    // MARK: Tests

    /// Test that tapping the more button dispatches the `.morePressed` action.
    func test_moreButton_tap() async throws {
        let button = try subject.inspect().find(asyncButtonWithAccessibilityLabel: Localizations.more)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .morePressed)
    }

    /// Test that tapping the totp copy button dispatches the `.copyTOTPCode` action.
    func test_totpCopyButton_tap() throws {
        let totp = VaultListTOTP.fixture()
        processor.state = VaultListItemRowState(
            item: .fixtureTOTP(
                totp: totp
            ),
            hasDivider: false,
            showWebIcons: true
        )
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.copyTotp)
        try button.tap()
        waitFor(!processor.dispatchedActions.isEmpty)
        XCTAssertEqual(processor.dispatchedActions.last, .copyTOTPCode(totp.totpCode.code))
    }

    // MARK: Snapshots

    /// Test that the default view renders correctly.
    func test_snapshot_default() {
        assertSnapshot(of: subject, as: .sizeThatFits)
    }

    /// Test that the view renders correctly with a custom icon.
    func test_snapshot_showWebIcon() {
        processor.state.iconBaseURL = .example
        processor.state.item = .fixture(cipherView: .fixture(login: .fixture(uris: [
            .init(
                uri: "Test",
                match: nil
            ),
        ])))
        assertSnapshot(of: subject, as: .sizeThatFits)
    }
}
