import BitwardenSdk
import SnapshotTesting
import XCTest

@testable import BitwardenShared

final class ProfileSwitcherToolbarViewTests: BitwardenTestCase {
    var processor: MockProcessor<ProfileSwitcherState, ProfileSwitcherAction, Void>!
    var subject: ProfileSwitcherToolbarView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        let account = ProfileSwitcherItem.anneAccount
        let state = ProfileSwitcherState(
            accounts: [account],
            activeAccountId: account.userId,
            isVisible: true
        )
        processor = MockProcessor(state: state)
        subject = ProfileSwitcherToolbarView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    /// Tapping the view dispatches the `.requestedProfileSwitcher` action.
    func test_tap_currentAccount() throws {
        let view = try subject.inspect().find(button: "AA")
        try view.tap()

        XCTAssertEqual(
            processor.dispatchedActions.last,
            .requestedProfileSwitcher(visible: !subject.store.state.isVisible)
        )
    }

    // MARK: Snapshots

    func test_snapshot_empty() {
        processor.state = .empty()
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    func test_snapshot_noActive() {
        processor.state = .init(
            accounts: [ProfileSwitcherItem.anneAccount],
            activeAccountId: nil,
            isVisible: true
        )
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    func test_snapshot_singleAccount() {
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    func test_snapshot_multi() {
        processor.state = .init(
            accounts: [
                ProfileSwitcherItem.anneAccount,
                ProfileSwitcherItem(
                    color: .blue,
                    email: "",
                    isUnlocked: true,
                    userId: "123",
                    userInitials: "OW"
                ),
            ],
            activeAccountId: "123",
            isVisible: true
        )
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }
}
