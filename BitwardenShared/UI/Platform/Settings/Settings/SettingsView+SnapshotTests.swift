// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

// MARK: - SettingsViewTests

@testable import BitwardenShared

class SettingsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<SettingsState, SettingsAction, Void>!
    var subject: SettingsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: SettingsState())
        let store = Store(processor: processor)

        subject = SettingsView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// Tests the view renders correctly.
    func disabletest_snapshot_viewRender() {
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    /// Tests the view renders correctly for the pre-login mode.
    @MainActor
    func disabletest_snapshot_viewRender_preLogin() {
        processor.state.presentationMode = .preLogin
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    /// Tests the view renders correctly with badges.
    @MainActor
    func disabletest_snapshot_settingsView_badges() {
        processor.state.badgeState = .fixture(
            autofillSetupProgress: .setUpLater,
            importLoginsSetupProgress: .setUpLater,
            vaultUnlockSetupProgress: .setUpLater,
        )
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }
}
