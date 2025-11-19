// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class VaultUnlockSetupViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultUnlockSetupState, VaultUnlockSetupAction, VaultUnlockSetupEffect>!
    var subject: VaultUnlockSetupView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: VaultUnlockSetupState(accountSetupFlow: .createAccount))

        subject = VaultUnlockSetupView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The vault unlock setup view renders correctly.
    @MainActor
    func disabletest_snapshot_vaultUnlockSetup() {
        processor.state.biometricsStatus = .available(.faceID, enabled: false)
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2), .defaultLandscape],
        )
    }

    /// The vault unlock setup view renders correctly when shown from settings.
    @MainActor
    func disabletest_snapshot_vaultUnlockSetup_settings() {
        processor.state.accountSetupFlow = .settings
        processor.state.biometricsStatus = .available(.faceID, enabled: false)
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2)],
        )
    }

    /// The vault unlock setup view renders correctly for a device with Touch ID.
    @MainActor
    func disabletest_snapshot_vaultUnlockSetup_touchID() {
        processor.state.biometricsStatus = .available(.touchID, enabled: false)
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait],
        )
    }

    /// The vault unlock setup view renders correctly for a device without biometrics.
    @MainActor
    func disabletest_snapshot_vaultUnlockSetup_noBiometrics() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait],
        )
    }

    /// The vault unlock setup view renders correctly with an unlock method enabled.
    @MainActor
    func disabletest_snapshot_vaultUnlockSetup_unlockMethodEnabled() {
        processor.state.biometricsStatus = .available(.faceID, enabled: true)
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait],
        )
    }
}
