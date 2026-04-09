// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class VaultUnlockViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultUnlockState, VaultUnlockAction, VaultUnlockEffect>!
    var subject: VaultUnlockView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(
            state: VaultUnlockState(
                email: "user@bitwarden.com",
                profileSwitcherState: .init(
                    accounts: [],
                    activeAccountId: nil,
                    allowLockAndLogout: false,
                    isVisible: false,
                ),
                unlockMethod: .password,
                webVaultHost: "bitwarden.com",
            ),
        )
        let store = Store(processor: processor)

        subject = VaultUnlockView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// Test a snapshot of the empty view.
    func disabletest_snapshot_vaultUnlock_empty() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Test a snapshot of the view with face id biometrics available.
    @MainActor
    func disabletest_snapshot_vaultUnlock_withBiometrics_faceId() {
        processor.state.biometricUnlockStatus = .available(
            .faceID,
            enabled: true,
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Test a snapshot of the view with biometrics unavailable.
    @MainActor
    func disabletest_snapshot_vaultUnlock_withBiometrics_notAvailable() {
        processor.state.biometricUnlockStatus = .notAvailable
        assertSnapshot(of: subject, as: .defaultLandscape)
    }

    /// Test a snapshot of the view with touch id biometrics available.
    @MainActor
    func disabletest_snapshot_vaultUnlock_withBiometrics_touchId() {
        processor.state.biometricUnlockStatus = .available(
            .touchID,
            enabled: true,
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Test a snapshot of the view with no master password or pin but with touch id.
    @MainActor
    func disabletest_snapshot_shouldShowPasswordOrPinFields_false_touchId() {
        processor.state.shouldShowPasswordOrPinFields = false
        processor.state.biometricUnlockStatus = .available(
            .touchID,
            enabled: true,
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Test a snapshot of the view with no master password or pin but with face id.
    @MainActor
    func disabletest_snapshot_shouldShowPasswordOrPinFields_false_faceId() {
        processor.state.shouldShowPasswordOrPinFields = false
        processor.state.biometricUnlockStatus = .available(
            .faceID,
            enabled: true,
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Test a snapshot of the view with no master password but with pin.
    @MainActor
    func disabletest_snapshot_shouldShowPasswordOrPinFields_true_pin() {
        processor.state.shouldShowPasswordOrPinFields = true
        processor.state.unlockMethod = .pin
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Test a snapshot of the view when the password is hidden.
    @MainActor
    func disabletest_snapshot_vaultUnlock_passwordHidden() {
        processor.state.masterPassword = "Password"
        processor.state.isMasterPasswordRevealed = false
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Test a snapshot of the view when the password is revealed.
    @MainActor
    func disabletest_snapshot_vaultUnlock_passwordRevealed() {
        processor.state.masterPassword = "Password"
        processor.state.isMasterPasswordRevealed = true
        assertSnapshot(of: subject, as: .defaultPortrait)
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
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Check the snapshot for the profiles visible
    @MainActor
    func disabletest_snapshot_profilesVisible_max() {
        processor.state.profileSwitcherState = .maximumAccounts
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Check the snapshot for the profiles visible
    @MainActor
    func disabletest_snapshot_profilesVisible_max_largeText() {
        processor.state.profileSwitcherState = .maximumAccounts
        assertSnapshot(of: subject, as: .defaultPortraitAX5)
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
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
