// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

// MARK: - SettingsViewTests

@testable import AuthenticatorShared

class SettingsViewTests: BitwardenTestCase {
    // MARK: Properties

    let copyrightText = "© Bitwarden Inc. 2015-2024" // Copyrights with snapshot tests shouldn't be dynamic
    let version = "Version: 1.0.0 (1)"

    var processor: MockProcessor<SettingsState, SettingsAction, SettingsEffect>!
    var subject: SettingsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: SettingsState(copyrightText: copyrightText, version: version))
        let store = Store(processor: processor)

        subject = SettingsView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tests the view renders correctly.
    func disabletest_snapshot_viewRender() {
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Tests the view renders correctly.
    @MainActor
    func disabletest_snapshot_viewRenderWithBiometricsAvailable() {
        processor.state.biometricUnlockStatus = .available(.faceID, enabled: false, hasValidIntegrity: true)
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Tests the view renders correctly with `shouldShowDefaultSaveOption` set to `true`.
    @MainActor
    func disabletest_snapshot_viewRenderWithDefaultSaveOption() {
        processor.state.shouldShowDefaultSaveOption = true
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }
}
