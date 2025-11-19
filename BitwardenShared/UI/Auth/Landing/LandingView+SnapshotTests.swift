// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - LandingViewTests

class LandingViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<LandingState, LandingAction, LandingEffect>!
    var subject: LandingView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: LandingState())
        let store = Store(processor: processor)
        subject = LandingView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// Check the snapshot for the empty state.
    @MainActor
    func disabletest_snapshot_empty() {
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// Check the snapshot when the email text field has a value.
    @MainActor
    func disabletest_snapshot_email_value() {
        processor.state.email = "email@example.com"
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// Check the snapshot when the remember me toggle is on.
    @MainActor
    func disabletest_snapshot_isRememberMeOn_true() {
        processor.state.isRememberMeOn = true
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// Check the snapshot for the profiles visible
    @MainActor
    func disabletest_snapshot_profilesVisible() {
        let account = ProfileSwitcherItem.fixture(
            email: "extra.warden@bitwarden.com",
            userInitials: "EW",
        )
        processor.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [
                account,
            ],
            activeAccountId: account.userId,
            allowLockAndLogout: true,
            isVisible: true,
        )
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// Check the snapshot for the profiles closed
    @MainActor
    func disabletest_snapshot_profilesClosed() {
        let account = ProfileSwitcherItem.fixture(
            email: "extra.warden@bitwarden.com",
            userInitials: "EW",
        )
        processor.state.profileSwitcherState = ProfileSwitcherState(
            accounts: [
                account,
            ],
            activeAccountId: account.userId,
            allowLockAndLogout: true,
            isVisible: false,
        )
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
