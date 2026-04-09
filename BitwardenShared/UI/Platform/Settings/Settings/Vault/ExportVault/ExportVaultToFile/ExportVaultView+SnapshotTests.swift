// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class ExportVaultViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<ExportVaultState, ExportVaultAction, ExportVaultEffect>!
    var subject: ExportVaultView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: ExportVaultState())
        let store = Store(processor: processor)

        subject = ExportVaultView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The empty view renders correctly.
    @MainActor
    func disabletest_snapshot_empty() {
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The populated view renders correctly.
    @MainActor
    func disabletest_snapshot_populated() {
        processor.state.masterPasswordOrOtpText = "password"
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The vault export disabled view renders correctly.
    @MainActor
    func disabletest_snapshot_vaultExportDisabled() {
        processor.state.disableIndividualVaultExport = true
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The JSON encrypted view renders correctly.
    @MainActor
    func disabletest_snapshot_jsonEncrypted() {
        processor.state.fileFormat = .jsonEncrypted
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }

    /// The view for exporting the vault without a master password renders correctly.
    @MainActor
    func disabletest_snapshot_noMasterPassword() {
        processor.state.hasMasterPassword = false
        assertSnapshots(of: subject.navStackWrapped, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
