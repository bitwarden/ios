import SnapshotTesting
import ViewInspector
import XCTest

@testable import BitwardenShared

class AccountSecurityViewTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
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

    // MARK: Tests

    /// Tapping the Account fingerprint phrase button dispatches the `.accountFingerprintPhrasePressed` effect.
    @MainActor
    func test_accountFingerprintPhrase_tap() throws {
        let button = try subject.inspect().find(button: Localizations.accountFingerprintPhrase)
        let task = Task {
            try button.tap()
        }
        waitFor(processor.effects.last == .accountFingerprintPhrasePressed)
        task.cancel()
    }

    /// The view hides the authenticator sync section when appropriate.
    @MainActor
    func test_authenticatorSync_hidden() throws {
        processor.state.shouldShowAuthenticatorSyncSection = false
        XCTAssertNil(
            try? subject.inspect().find(
                toggleWithAccessibilityLabel: Localizations.allowAuthenticatorSyncing
            )
        )
    }

    /// Tapping the sync with authenticator switch should send `.toggleSyncWithAuthenticator(enabled)` with the
    /// new value of enabled.
    @MainActor
    func test_authenticatorSync_tap() throws {
        processor.state.shouldShowAuthenticatorSyncSection = true
        processor.state.isAuthenticatorSyncEnabled = false
        let toggle = try subject.inspect().find(toggleWithAccessibilityLabel: Localizations.allowAuthenticatorSyncing)
        XCTAssertFalse(try toggle.isOn())

        let task = Task {
            try toggle.tap()
        }
        defer { task.cancel() }
        waitFor(processor.effects.last == .toggleSyncWithAuthenticator(true))
    }

    /// The action card is hidden if the vault unlock setup progress is complete.
    @MainActor
    func test_setUpUnlockActionCard_hidden() {
        processor.state.badgeState = .fixture(vaultUnlockSetupProgress: .complete)
        XCTAssertThrowsError(try subject.inspect().find(ActionCard<BitwardenBadge>.self))
    }

    /// The action card is visible if the vault unlock setup progress isn't complete.
    @MainActor
    func test_setUpUnlockActionCard_visible() async throws {
        processor.state.badgeState = .fixture(vaultUnlockSetupProgress: .setUpLater)
        let actionCard = try subject.inspect().find(actionCard: Localizations.getStarted)

        let badge = try actionCard.find(BitwardenBadge.self)
        try XCTAssertEqual(badge.text().string(), "1")
    }

    /// Tapping the dismiss button in the set up unlock action card sends the
    /// `.dismissSetUpUnlockActionCard` effect.
    @MainActor
    func test_setUpUnlockActionCard_visible_tapDismiss() async throws {
        processor.state.badgeState = .fixture(vaultUnlockSetupProgress: .setUpLater)
        let actionCard = try subject.inspect().find(actionCard: Localizations.setUpUnlock)

        let button = try actionCard.find(asyncButton: Localizations.dismiss)
        try await button.tap()
        XCTAssertEqual(processor.effects, [.dismissSetUpUnlockActionCard])
    }

    /// Tapping the get started button in the set up unlock action card sends the
    /// `.showSetUpUnlock` action.
    @MainActor
    func test_setUpUnlockActionCard_visible_tapGetStarted() async throws {
        processor.state.badgeState = .fixture(vaultUnlockSetupProgress: .setUpLater)
        let actionCard = try subject.inspect().find(actionCard: Localizations.setUpUnlock)

        let button = try actionCard.find(asyncButton: Localizations.getStarted)
        try await button.tap()
        XCTAssertEqual(processor.dispatchedActions, [.showSetUpUnlock])
    }

    /// The view displays a biometrics toggle.
    @MainActor
    func test_biometricsToggle() throws {
        processor.state.biometricUnlockStatus = .available(.faceID, enabled: false)
        _ = try subject.inspect().find(
            toggleWithAccessibilityLabel: Localizations.unlockWith(Localizations.faceID)
        )
        processor.state.biometricUnlockStatus = .available(.touchID, enabled: true)
        _ = try subject.inspect().find(
            toggleWithAccessibilityLabel: Localizations.unlockWith(Localizations.touchID)
        )
    }

    /// The view hides the biometrics toggle when appropriate.
    @MainActor
    func test_biometricsToggle_hidden() throws {
        processor.state.biometricUnlockStatus = .notAvailable
        XCTAssertNil(
            try? subject.inspect().find(
                toggleWithAccessibilityLabel: Localizations.unlockWith(Localizations.faceID)
            )
        )
    }

    /// Tapping the delete account button dispatches the `.deleteAccountPressed` action.
    @MainActor
    func test_deleteAccountButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.deleteAccount)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .deleteAccountPressed)
    }

    /// Tapping the lock now button dispatches the `.lockVault` effect.
    @MainActor
    func test_lockNowButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.lockNow)
        let task = Task {
            try button.tap()
        }
        waitFor(processor.effects.last == .lockVault)
        task.cancel()
    }

    /// Tapping the pending login requests button dispatches the `.pendingLoginRequestsTapped` action.
    @MainActor
    func test_pendingRequestsButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.pendingLogInRequests)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .pendingLoginRequestsTapped)
    }

    /// Tapping the log out button dispatches the `.logout` action.
    @MainActor
    func test_logOutButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.logOut)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .logout)
    }

    /// Tapping the two step login button dispatches the `.logout` action.
    @MainActor
    func test_twoStepLoginButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.twoStepLogin)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .twoStepLoginPressed)
    }

    /// Changing the unlock with pin toggle dispatches the `.toggleUnlockWithPINCode(_)` action.
    @MainActor
    func test_unlockWithPinToggle_changed() throws {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            throw XCTSkip("Unable to run test in iOS 16, keep an eye on ViewInspector to see if it gets updated.")
        }
        let toggle = try subject.inspect().find(ViewType.Toggle.self)
        try toggle.tap()
        XCTAssertEqual(processor.effects.last, .toggleUnlockWithPINCode(true))
    }

    /// When `.removeUnlockWithPin` policy is enabled and unlock with pin is disabled then Unlock with Pin is not shown.
    @MainActor
    func test_unlockWithPin_removeUnlockWithPinPolicyEnabled() throws {
        processor.state.removeUnlockWithPinPolicyEnabled = true
        XCTAssertThrowsError(try subject.inspect().find(toggleWithAccessibilityLabel: Localizations.unlockWithPIN))
    }

    /// When `.removeUnlockWithPin` policy is enabled and unlock with pin is enabled then Unlock with Pin is shown.
    @MainActor
    func test_unlockWithPin_removeUnlockWithPinPolicyEnabledWithPinEnabled() throws {
        processor.state.removeUnlockWithPinPolicyEnabled = true
        processor.state.isUnlockWithPINCodeOn = true
        XCTAssertNoThrow(try subject.inspect().find(toggleWithAccessibilityLabel: Localizations.unlockWithPIN))
    }

    /// When `.removeUnlockWithPin` policy is enabled, unlock with pin disabled and biometrics is disabled then entire
    /// Unlock options section is not shown.
    @MainActor
    func test_unlockWithPin_removeUnlockWithPinPolicyEnabledNoPinNorBiometrics() throws {
        processor.state.removeUnlockWithPinPolicyEnabled = true
        processor.state.isUnlockWithPINCodeOn = false
        XCTAssertThrowsError(try subject.inspect().find(text: Localizations.unlockOptions))
        XCTAssertThrowsError(try subject.inspect().find(toggleWithAccessibilityLabel: Localizations.unlockWithPIN))
        XCTAssertThrowsError(try subject.inspect().find(ViewType.Toggle.self) { view in
            try view.accessibilityIdentifier() == "UnlockWithBiometricsSwitch"
        })
    }

    // MARK: Snapshots

    /// The view renders correctly with the vault unlock action card is displayed.
    @MainActor
    func test_snapshot_actionCardVaultUnlock() async {
        processor.state.badgeState = .fixture(vaultUnlockSetupProgress: .setUpLater)
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// The view renders correctly when biometrics are available.
    @MainActor
    func test_snapshot_biometricsDisabled_touchID() {
        let subject = AccountSecurityView(
            store: Store(
                processor: StateProcessor(
                    state: AccountSecurityState(
                        biometricUnlockStatus: .available(
                            .touchID,
                            enabled: false
                        ),
                        sessionTimeoutValue: .custom(1)
                    )
                )
            )
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The view renders correctly when biometrics are available.
    @MainActor
    func test_snapshot_biometricsEnabled_faceID() {
        let subject = AccountSecurityView(
            store: Store(
                processor: StateProcessor(
                    state: AccountSecurityState(
                        biometricUnlockStatus: .available(
                            .faceID,
                            enabled: true
                        ),
                        sessionTimeoutValue: .custom(1)
                    )
                )
            )
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The view renders correctly when showing the custom session timeout field.
    @MainActor
    func test_snapshot_customSessionTimeoutField() {
        let subject = AccountSecurityView(
            store: Store(
                processor: StateProcessor(
                    state: AccountSecurityState(sessionTimeoutValue: .custom(1))
                )
            )
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The view renders correctly when the user doesn't have a master password.
    @MainActor
    func test_snapshot_noMasterPassword() {
        let subject = AccountSecurityView(
            store: Store(
                processor: StateProcessor(
                    state: AccountSecurityState(
                        hasMasterPassword: false,
                        sessionTimeoutAction: .logout
                    )
                )
            )
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The view renders correctly when the remove unlock with pin policy is enabled.
    @MainActor
    func test_snapshot_removeUnlockPinPolicyEnabled() {
        let subject = AccountSecurityView(
            store: Store(
                processor: StateProcessor(
                    state: AccountSecurityState(
                        biometricUnlockStatus: .available(.faceID, enabled: true),
                        removeUnlockWithPinPolicyEnabled: true
                    )
                )
            )
        )
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5()]
        )
    }

    /// The view renders correctly when the `shouldShowAuthenticatorSyncSection` is `true`.
    @MainActor
    func test_snapshot_shouldShowAuthenticatorSyncSection() {
        let subject = AccountSecurityView(
            store: Store(
                processor: StateProcessor(
                    state: AccountSecurityState(shouldShowAuthenticatorSyncSection: true)
                )
            )
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The view renders correctly when the timeout policy is enabled.
    @MainActor
    func test_snapshot_timeoutPolicy() {
        let subject = AccountSecurityView(
            store: Store(
                processor: StateProcessor(
                    state: AccountSecurityState(
                        isTimeoutPolicyEnabled: true,
                        sessionTimeoutValue: .custom(1)
                    )
                )
            )
        )
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5()]
        )
    }

    /// The view renders correctly when the timeout policy with an action is enabled.
    @MainActor
    func test_snapshot_timeoutPolicyWithAction() {
        let subject = AccountSecurityView(
            store: Store(
                processor: StateProcessor(
                    state: AccountSecurityState(
                        isTimeoutPolicyEnabled: true,
                        policyTimeoutAction: .logout,
                        sessionTimeoutAction: .logout,
                        sessionTimeoutValue: .custom(1)
                    )
                )
            )
        )
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5()]
        )
    }

    /// The view renders correctly.
    @MainActor
    func test_view_render() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
