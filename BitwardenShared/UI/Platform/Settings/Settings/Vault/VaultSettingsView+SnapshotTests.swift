// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class VaultSettingsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultSettingsState, VaultSettingsAction, VaultSettingsEffect>!
    var subject: VaultSettingsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: VaultSettingsState())
        let store = Store(processor: processor)

        subject = VaultSettingsView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The view renders correctly with the import logins action card displayed.
    @MainActor
    func disabletest_snapshot_actionCardImportLogins() async {
        processor.state.badgeState = .fixture(importLoginsSetupProgress: .setUpLater)
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// The default view renders correctly.
    @MainActor
    func disabletest_snapshot_default() {
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
