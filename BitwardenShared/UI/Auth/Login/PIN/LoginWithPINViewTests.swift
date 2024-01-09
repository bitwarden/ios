import SnapshotTesting
import ViewInspector
import XCTest

@testable import BitwardenShared

class LoginWithPINViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<LoginWithPINState, LoginWithPINAction, LoginWithPINEffect>!
    var subject: LoginWithPINView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: LoginWithPINState())
        let store = Store(processor: processor)

        subject = LoginWithPINView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The view renders correctly.
    func test_view_render() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Check the snapshot for the profiles visible
    func test_snapshot_profilesVisible() {
        let account = ProfileSwitcherItem(
            email: "extra.warden@bitwarden.com",
            userInitials: "EW"
        )
        processor.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [
                account,
            ],
            activeAccountId: account.userId,
            isVisible: true
        )
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    /// Check the snapshot for the profiles closed
    func test_snapshot_profilesClosed() {
        let account = ProfileSwitcherItem(
            email: "extra.warden@bitwarden.com",
            userInitials: "EW"
        )
        processor.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [
                account,
            ],
            activeAccountId: account.userId,
            isVisible: false
        )
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    // MARK: Button taps

    /// Tapping the logout button dispatches the logout effect.
    func test_logout_buttonTap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.logOut)
        try await button.tap()
        XCTAssertEqual(processor.effects, [.logout])
    }
}
