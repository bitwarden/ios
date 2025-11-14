// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class AccountSecurityViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AccountSecurityState, AccountSecurityAction, AccountSecurityEffect>!
    var subject: AccountSecurityView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AccountSecurityState())
        let store = Store(processor: processor)

        subject = AccountSecurityView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The view renders correctly with the vault unlock action card is displayed.
    @MainActor
    func disabletest_snapshot_actionCardVaultUnlock() async {
        processor.state.badgeState = .fixture(vaultUnlockSetupProgress: .setUpLater)
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// The view renders correctly when biometrics are available.
    @MainActor
    func disabletest_snapshot_biometricsDisabled_touchID() {
        let subject = AccountSecurityView(
            store: Store(
                processor: StateProcessor(
                    state: AccountSecurityState(
                        biometricUnlockStatus: .available(
                            .touchID,
                            enabled: false,
                        ),
                        sessionTimeoutValue: .custom(1),
                    ),
                ),
            ),
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The view renders correctly when biometrics are available.
    @MainActor
    func disabletest_snapshot_biometricsEnabled_faceID() {
        let subject = AccountSecurityView(
            store: Store(
                processor: StateProcessor(
                    state: AccountSecurityState(
                        biometricUnlockStatus: .available(
                            .faceID,
                            enabled: true,
                        ),
                        sessionTimeoutValue: .custom(1),
                    ),
                ),
            ),
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The view renders correctly when showing the custom session timeout field.
    @MainActor
    func disabletest_snapshot_customSessionTimeoutField() {
        let subject = AccountSecurityView(
            store: Store(
                processor: StateProcessor(
                    state: AccountSecurityState(sessionTimeoutValue: .custom(1)),
                ),
            ),
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The view renders correctly when the user doesn't have a master password.
    @MainActor
    func disabletest_snapshot_noMasterPassword() {
        let subject = AccountSecurityView(
            store: Store(
                processor: StateProcessor(
                    state: AccountSecurityState(
                        hasMasterPassword: false,
                        sessionTimeoutAction: .logout,
                    ),
                ),
            ),
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The view renders correctly when the remove unlock with pin policy is enabled.
    @MainActor
    func disabletest_snapshot_removeUnlockPinPolicyEnabled() {
        let subject = AccountSecurityView(
            store: Store(
                processor: StateProcessor(
                    state: AccountSecurityState(
                        biometricUnlockStatus: .available(.faceID, enabled: true),
                        removeUnlockWithPinPolicyEnabled: true,
                    ),
                ),
            ),
        )
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5()],
        )
    }

    /// The view renders correctly when the timeout policy is enabled.
    @MainActor
    func disabletest_snapshot_timeoutPolicy() {
        let subject = AccountSecurityView(
            store: Store(
                processor: StateProcessor(
                    state: AccountSecurityState(
                        isTimeoutPolicyEnabled: true,
                        sessionTimeoutValue: .custom(1),
                    ),
                ),
            ),
        )
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5()],
        )
    }

    /// The view renders correctly when the timeout policy with an action is enabled.
    @MainActor
    func disabletest_snapshot_timeoutPolicyWithAction() {
        let subject = AccountSecurityView(
            store: Store(
                processor: StateProcessor(
                    state: AccountSecurityState(
                        isTimeoutPolicyEnabled: true,
                        policyTimeoutAction: .logout,
                        sessionTimeoutAction: .logout,
                        sessionTimeoutValue: .custom(1),
                    ),
                ),
            ),
        )
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5()],
        )
    }

    /// The view renders correctly.
    @MainActor
    func disabletest_view_render() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
