import SnapshotTesting
import ViewInspector
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

    // MARK: Tests

    /// Tapping the Account fingerprint phrase button dispatches the `.accountFingerprintPhrasePressed` effect.
    func test_accountFingerprintPhrase_tap() throws {
        let button = try subject.inspect().find(button: Localizations.accountFingerprintPhrase)
        let task = Task {
            try button.tap()
        }
        waitFor(processor.effects.last == .accountFingerprintPhrasePressed)
        task.cancel()
    }

    /// The view displays a biometrics toggle.
    func test_biometricsToggle() throws {
        processor.state.biometricUnlockStatus = .available(.faceID, enabled: false, hasValidIntegrity: false)
        _ = try subject.inspect().find(
            toggleWithAccessibilityLabel: Localizations.unlockWith(Localizations.faceID)
        )
        processor.state.biometricUnlockStatus = .available(.touchID, enabled: true, hasValidIntegrity: true)
        _ = try subject.inspect().find(
            toggleWithAccessibilityLabel: Localizations.unlockWith(Localizations.touchID)
        )
    }

    /// The view hides the biometrics toggle when appropriate.
    func test_biometricsToggle_hidden() throws {
        processor.state.biometricUnlockStatus = .notAvailable
        XCTAssertNil(
            try? subject.inspect().find(
                toggleWithAccessibilityLabel: Localizations.unlockWith(Localizations.faceID)
            )
        )
    }

    /// Tapping the delete account button dispatches the `.deleteAccountPressed` action.
    func test_deleteAccountButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.deleteAccount)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .deleteAccountPressed)
    }

    /// Tapping the lock now button dispatches the `.lockVault` effect.
    func test_lockNowButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.lockNow)
        let task = Task {
            try button.tap()
        }
        waitFor(processor.effects.last == .lockVault)
        task.cancel()
    }

    /// Tapping the pending login requests button dispatches the `.pendingLoginRequestsTapped` action.
    func test_pendingRequestsButton_tap() throws {
        processor.state.isApproveLoginRequestsToggleOn = true
        let button = try subject.inspect().find(button: Localizations.pendingLogInRequests)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .pendingLoginRequestsTapped)
    }

    /// Tapping the log out button dispatches the `.logout` action.
    func test_logOutButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.logOut)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .logout)
    }

    /// Tapping the two step login button dispatches the `.logout` action.
    func test_twoStepLoginButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.twoStepLogin)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .twoStepLoginPressed)
    }

    /// Changing the unlock with pin toggle dispatches the `.toggleUnlockWithPINCode(_)` action.
    func test_unlockWithPinToggle_changed() throws {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            throw XCTSkip("Unable to run test in iOS 16, keep an eye on ViewInspector to see if it gets updated.")
        }
        let toggle = try subject.inspect().find(ViewType.Toggle.self)
        try toggle.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .toggleUnlockWithPINCode(true))
    }

    // MARK: Snapshots

    /// The view renders correctly when biometrics are available.
    func test_snapshot_biometricsDisabled_touchID() {
        let subject = AccountSecurityView(
            store: Store(
                processor: StateProcessor(
                    state: AccountSecurityState(
                        biometricUnlockStatus: .available(
                            .touchID,
                            enabled: false,
                            hasValidIntegrity: true
                        ),
                        isApproveLoginRequestsToggleOn: true,
                        sessionTimeoutValue: .custom(60)
                    )
                )
            )
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The view renders correctly when biometrics are available.
    func test_snapshot_biometricsEnabled_faceID() {
        let subject = AccountSecurityView(
            store: Store(
                processor: StateProcessor(
                    state: AccountSecurityState(
                        biometricUnlockStatus: .available(
                            .faceID,
                            enabled: true,
                            hasValidIntegrity: true
                        ),
                        isApproveLoginRequestsToggleOn: true,
                        sessionTimeoutValue: .custom(60)
                    )
                )
            )
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The view renders correctly when biometrics are available.
    func test_snapshot_biometricsEnabled_faceID_nonValidIntegrity_dark() {
        let subject = AccountSecurityView(
            store: Store(
                processor: StateProcessor(
                    state: AccountSecurityState(
                        biometricUnlockStatus: .available(
                            .faceID,
                            enabled: true,
                            hasValidIntegrity: false
                        ),
                        isApproveLoginRequestsToggleOn: true,
                        sessionTimeoutValue: .custom(60)
                    )
                )
            )
        )
        assertSnapshot(of: subject, as: .defaultPortraitDark)
    }

    /// The view renders correctly when showing the custom session timeout field.
    func test_snapshot_customSessionTimeoutField() {
        let subject = AccountSecurityView(
            store: Store(
                processor: StateProcessor(
                    state: AccountSecurityState(
                        isApproveLoginRequestsToggleOn: true,
                        sessionTimeoutValue: .custom(60)
                    )
                )
            )
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The view renders correctly when the timeout policy is enabled.
    func test_snapshot_timeoutPolicy() {
        let subject = AccountSecurityView(
            store: Store(
                processor: StateProcessor(
                    state: AccountSecurityState(
                        isApproveLoginRequestsToggleOn: true,
                        isTimeoutPolicyEnabled: true,
                        sessionTimeoutValue: .custom(60)
                    )
                )
            )
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The view renders correctly.
    func test_view_render() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
